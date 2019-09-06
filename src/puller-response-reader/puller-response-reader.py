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

parser = argparse.ArgumentParser(description="Read items from the puller-reponse-queue, and write new items to the puller-queue based on them")

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

    for queue_message in puller_response_queue:
        response = PullerResponseQueueItem.from_json(queue_message.get_message_body())

        logging.info(f"Received response message: User ID: {response.get_user_id()}, neighbor list requested: {str(response.get_neighbor_list_requested())}")

        if response.get_neighbor_list_requested():

            neighbors_to_request_data_for = [PullerQueueItem(user_id=user_id, request_favorites=True, request_contacts=False, request_neighbor_list=False) for user_id in response.get_neighbor_list()]

            logging.info(f"Found {len(neighbors_to_request_data_for)} neighbors who need their data updated. Sending messages to queue {puller_queue_url} in batches of {puller_queue_batch_size}")

            if len(neighbors_to_request_data_for) > 0:
                puller_queue.send_messages(objects=neighbors_to_request_data_for, to_string=lambda user : user.to_json())

                if logging.getLogger().getEffectiveLevel() <= logging.INFO:
                    for neighbor in neighbors_to_request_data_for:
                        logging.info(f"Requested data for neighbor {neighbor.get_user_id()}")

        puller_response_queue.finished_with_message(queue_message)

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