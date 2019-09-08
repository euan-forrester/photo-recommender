#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
from queuereader import SQSQueueReader
from confighelper import ConfigHelper
from metricshelper import MetricsHelper
from unhandledexceptionhelper import UnhandledExceptionHelper
from ingesterresponsequeueitem import IngesterResponseQueueItem
from usersstoreapiserver import UsersStoreAPIServer
from usersstoreexception import UsersStoreException
#
# Read in commandline arguments
#

parser = argparse.ArgumentParser(description="Read items from the ingester-reponse-queue, and write to the API server that we received them")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="ingester-response-reader")

metrics_namespace                   = config_helper.get("metrics-namespace")

api_server_host                     = config_helper.get("api-server-host")
api_server_port                     = config_helper.getInt("api-server-port")

ingester_response_queue_url           = config_helper.get("ingester-response-queue-url")
ingester_response_queue_batch_size    = config_helper.getInt("ingester-response-queue-batchsize")
ingester_response_queue_max_items_to_process = config_helper.getInt("ingester-response-queue-maxitemstoprocess")

#
# Metrics and unhandled exceptions
#

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="ingester-response-reader", metrics_namespace=metrics_namespace)
unhandled_exception_helper  = UnhandledExceptionHelper.setup_unhandled_exception_handler(metrics_helper=metrics_helper)

#
# Initialize our users' store and queue
# 

users_store             = UsersStoreAPIServer(host=api_server_host, port=api_server_port)
ingester_response_queue = SQSQueueReader(ingester_response_queue_url, ingester_response_queue_batch_size, ingester_response_queue_max_items_to_process, metrics_helper)

#
# Process any ingester response messages
#

logging.info("Beginning processing ingester response messages")

try:

    messages_received = {} # Keep track of how many messages we received for each user, so we can do batch calls at the end rather than many individual calls

    for queue_message in ingester_response_queue:
        response = IngesterResponseQueueItem.from_json(queue_message.get_message_body())

        user_id = response.get_user_id()
        initial_requesting_user_id = response.get_initial_requesting_user_id();

        if not initial_requesting_user_id in messages_received:
            messages_received[initial_requesting_user_id] = {
                'count': 0
            }

        messages_received[initial_requesting_user_id]['count'] += 1

        logging.info(f"Received response message: User ID: {user_id}, initial requesting user ID: {initial_requesting_user_id}, contained num favorites: {response.get_contained_num_favorites()}, contained num contacts: {response.get_contained_num_contacts()}")

        ingester_response_queue.finished_with_message(queue_message)

    # Now that we have no new messages to process, tell the API server how many messages we saw for each user

    for initial_requesting_user_id in messages_received:
        logging.info(f"Telling users store that we received {messages_received[initial_requesting_user_id]['count']} responses for initial requesting user {initial_requesting_user_id}")
        processing_status = users_store.received_ingester_responses(initial_requesting_user_id, messages_received[initial_requesting_user_id]['count'])

        if processing_status['finished_processing']:
            time_in_seconds = users_store.get_time_to_update_all_data(initial_requesting_user_id)
            logging.info(f"We have finished processing user {initial_requesting_user_id}. It took {time_in_seconds}")
            metrics_helper.send_time("time_to_get_all_data", time_in_seconds)

except UsersStoreException as e:
    logging.error("Unable to talk to our users store. Exiting.", e)
    metrics_helper.increment_count("UsersStoreException")
    sys.exit()

finally:
    ingester_response_queue.shutdown()

logging.info("Ended processing ingester response messages")

#
# And we're finished
#

logging.info("ingester-response-reader successfully completed processing")