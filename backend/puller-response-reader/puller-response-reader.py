#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
from queuewriter import SQSQueueWriter
from queuereader import SQSQueueReader
from confighelper import ConfigHelper
from metricshelper import MetricsHelper
from unhandledexceptionhelper import UnhandledExceptionHelper
from pullerqueueitem import PullerQueueItem
from pullerresponsequeueitem import PullerResponseQueueItem
from usersstoreapiserver import UsersStoreAPIServer
from usersstoreexception import UsersStoreException
#
# Read in commandline arguments
#

parser = argparse.ArgumentParser(description="Read items from the puller-reponse-queue, write new items to the puller-queue based on them, and write to the API server that we received them.")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="puller-response-reader")

metrics_namespace                   = config_helper.get("metrics-namespace")

api_server_host                     = config_helper.get("api-server-host")
api_server_port                     = config_helper.getInt("api-server-port")

puller_queue_url                    = config_helper.get("puller-queue-url")
puller_queue_batch_size             = config_helper.getInt("puller-queue-batchsize")

puller_response_queue_url           = config_helper.get("puller-response-queue-url")
puller_response_queue_batch_size    = config_helper.getInt("puller-response-queue-batchsize")
puller_response_queue_max_items_to_process = config_helper.getInt("puller-response-queue-maxitemstoprocess")

#
# Metrics and unhandled exceptions
#

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="puller-response-reader", metrics_namespace=metrics_namespace)
unhandled_exception_helper  = UnhandledExceptionHelper.setup_unhandled_exception_handler(metrics_helper=metrics_helper)

#
# Initialize our users' store and queues
# 

users_store             = UsersStoreAPIServer(host=api_server_host, port=api_server_port)

puller_queue            = SQSQueueWriter(puller_queue_url,          puller_queue_batch_size,                                                        metrics_helper)
puller_response_queue   = SQSQueueReader(puller_response_queue_url, puller_response_queue_batch_size, puller_response_queue_max_items_to_process,   metrics_helper)

#
# Process any puller response messages. If they contain a list of neighbors to request data for, then request those as well
#

logging.info("Beginning processing puller response messages")

try:

    messages_received = {} # Keep track of how many messages we received for each user, so we can do batch calls at the end rather than many individual calls

    for queue_message in puller_response_queue:
        response = PullerResponseQueueItem.from_json(queue_message.get_message_body())

        user_id = response.get_user_id()
        initial_requesting_user_id = response.get_initial_requesting_user_id();

        if not initial_requesting_user_id in messages_received:
            messages_received[initial_requesting_user_id] = {
                'count': 0
            }

        messages_received[initial_requesting_user_id]['count'] += 1

        logging.info(f"Received response message: User ID: {user_id}, initial requesting user ID: {initial_requesting_user_id}, neighbor list requested: {str(response.get_neighbor_list_requested())}")

        if response.get_neighbor_list_requested():

            neighbors_to_request_data_for = [PullerQueueItem(user_id=neighbor_user_id, initial_requesting_user_id=response.get_user_id(), request_favorites=True, request_contacts=False, request_neighbor_list=False) for neighbor_user_id in response.get_neighbor_list()]

            if len(neighbors_to_request_data_for) == 0:
                logging.warn("No neighbors in list despite requesting data for neighbors")

            else:
                logging.info(f"Found {len(neighbors_to_request_data_for)} neighbors who need their data updated. Sending messages to queue {puller_queue_url} in batches of {puller_queue_batch_size}")

                puller_queue.send_messages(objects=neighbors_to_request_data_for, to_string=lambda queue_item : queue_item.to_json())

                users_store.made_more_puller_requests(user_id, len(neighbors_to_request_data_for))

                if logging.getLogger().getEffectiveLevel() <= logging.INFO:
                    for neighbor in neighbors_to_request_data_for:
                        logging.info(f"Requested data for neighbor {neighbor.get_user_id()}")

        puller_response_queue.finished_with_message(queue_message)

    # Now that we have no new messages to process, tell the API server how many messages we saw for each user
    #
    # Note that we have to do this *after* making any more puller requests above, so that we don't 
    # accidentally mark this user as being complete if only their initial requests have been fully processed.

    for initial_requesting_user_id in messages_received:
        logging.info(f"Telling users store that we received {messages_received[initial_requesting_user_id]['count']} responses for initial requesting user {initial_requesting_user_id}")
        processing_status = users_store.received_puller_responses(initial_requesting_user_id, messages_received[initial_requesting_user_id]['count'])

        if processing_status['finished_processing']:
            time_in_seconds = users_store.get_time_to_update_all_data(initial_requesting_user_id)
            logging.info(f"We have finished processing user {initial_requesting_user_id}. It took {time_in_seconds}")
            metrics_helper.send_time("time_to_get_all_data", time_in_seconds)

except UsersStoreException as e:
    logging.error("Unable to talk to our users store. Exiting.", e)
    metrics_helper.increment_count("UsersStoreException")
    sys.exit()

finally:
    puller_response_queue.shutdown()

logging.info("Ended processing puller response messages")

#
# And we're finished
#

logging.info("puller-response-reader successfully completed processing")