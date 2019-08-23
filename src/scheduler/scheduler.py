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

parser = argparse.ArgumentParser(description="Schedule pulling of various users' data")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="scheduler")

metrics_namespace                   = config_helper.get("metrics-namespace")

api_server_host                     = config_helper.get("api-server-host")
api_server_port                     = config_helper.getInt("api-server-port")

puller_queue_url                    = config_helper.get("puller-queue-url")
puller_queue_batch_size             = config_helper.getInt("puller-queue-batchsize")

puller_response_queue_url           = config_helper.get("puller-response-queue-url")

scheduler_seconds_between_user_data_updates = config_helper.getInt("seconds-between-user-data-updates")

ingester_queue_url                  = config_helper.get("ingester-queue-url")

#
# Metrics and unhandled exceptions
#

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="scheduler", metrics_namespace=metrics_namespace)
unhandled_exception_helper  = UnhandledExceptionHelper.setup_unhandled_exception_handler(metrics_helper=metrics_helper)

#
# Initialize our users' store and queues
# 

users_store             = UsersStoreAPIServer(host=api_server_host, port=api_server_port)

puller_queue            = SQSQueueWriter(puller_queue_url, puller_queue_batch_size, metrics_helper)

puller_queue_reader     = SQSQueueReader(puller_queue_url,          0, 0, metrics_helper) # We're just going to read the size from this queue, and not read any of its messages. We only write to this queue
puller_response_queue   = SQSQueueReader(puller_response_queue_url, 0, 0, metrics_helper) # We're just going to read the size from this queue, not any of its messages
ingester_queue          = SQSQueueReader(ingester_queue_url,        0, 0, metrics_helper) # We're just going to read the size from this queue, not any of its messages

#
# Begin by requesting all of the users that haven't been updated in a while
#

logging.info("Beginning looking for users who haven't been updated in a while")

try:
    users_ids_to_request_data_for = users_store.get_users_to_request_data_for(scheduler_seconds_between_user_data_updates)

    users_to_request_data_for = [PullerQueueItem(user_id=user_id, is_registered_user=True) for user_id in users_ids_to_request_data_for]

    logging.info(f"Found {len(users_to_request_data_for)} registered users who need their data updated. Sending messages to queue {puller_queue_url} in batches of {puller_queue_batch_size}")

    puller_queue.send_messages(objects=users_to_request_data_for, to_string=lambda user : user.to_json())

    for user in users_to_request_data_for:
        logging.info(f"Requested data for user {user.get_user_id()}")
        users_store.data_requested(user.get_user_id())

except UsersStoreException as e:
    logging.error("Unable to talk to our users store. Exiting.", e)
    metrics_helper.increment_count("UsersStoreException")
    sys.exit()

logging.info("Ended looking for users who haven't been updated in a while")

#
# Find any users who are currently updating, and see if we've finished updating
#

logging.info("Beginning looking for users who are still updating")

try:
    user_ids_still_updating = users_store.get_users_that_are_currently_updating()

    if len(user_ids_still_updating) == 0:
        logging.info("No user IDs are currently updating")

    else:
        puller_queue_num_messages            = puller_queue_reader.get_total_number_of_messages_available()
        puller_response_queue_num_messages   = puller_response_queue.get_total_number_of_messages_available()
        ingester_queue_num_messages          = ingester_queue.get_total_number_of_messages_available()

        total_messages_in_system = puller_queue_num_messages + puller_response_queue_num_messages + ingester_queue_num_messages
            
        logging.info(f"Currently found {puller_queue_num_messages} puller messages, {puller_response_queue_num_messages} puller response messages, and {ingester_queue_num_messages} ingester messages, for a total of {total_messages_in_system}")

        if total_messages_in_system == 0:
            logging.info("No messages currently in the system, so we're done updating our users")
            
            for user_id in user_ids_still_updating:              
                users_store.all_data_updated(user_id)
                time_in_seconds = users_store.get_time_to_update_all_data(user_id)
                logging.info(f"It took {time_in_seconds} to update user {user_id}")
                metrics_helper.send_time("time_to_get_all_data", time_in_seconds)
        else:
            logging.info("There are still messages in the system, so we are not done updating our users")

except UsersStoreException as e:
    logging.error("Unable to talk to our users store. Exiting.", e)
    metrics_helper.increment_count("UsersStoreException")
    sys.exit() 

logging.info("Ended looking for users who are still updating")

#
# And we're finished
#

logging.info("Scheduler successfully completed processing")