#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
from queuewriter import SQSQueueWriter
from queuereader import SQSQueueReader
from confighelper import ConfigHelper
from schedulerqueueitem import SchedulerQueueItem
from schedulerresponsequeueitem import SchedulerResponseQueueItem
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

api_server_host                     = config_helper.get("api-server-host")
api_server_port                     = config_helper.getInt("api-server-port")

scheduler_queue_url                 = config_helper.get("scheduler-queue-url")
scheduler_queue_batch_size          = config_helper.getInt("scheduler-queue-batchsize")

scheduler_response_queue_url        = config_helper.get("scheduler-response-queue-url")
scheduler_response_queue_batch_size = config_helper.getInt("scheduler-response-queue-batchsize")
scheduler_response_queue_max_items_to_process = config_helper.getInt("scheduler-response-queue-maxitemstoprocess")

scheduler_seconds_between_user_data_updates = config_helper.getInt("seconds-between-user-data-updates")

#
# Initialize our users' store and queues
# 

users_store = UsersStoreAPIServer(host=api_server_host, port=api_server_port)

scheduler_queue = SQSQueueWriter(scheduler_queue_url, scheduler_queue_batch_size)

scheduler_response_queue = SQSQueueReader(scheduler_response_queue_url, scheduler_response_queue_batch_size, scheduler_response_queue_max_items_to_process)

#
# Begin by requesting all of the users that haven't been updated in a while
#

logging.info("Beginning looking for users who haven't been updated in a while")

try:
    users_ids_to_request_data_for = users_store.get_users_to_request_data_for(scheduler_seconds_between_user_data_updates)

    users_to_request_data_for = [SchedulerQueueItem(user_id=user_id, is_registered_user=True) for user_id in users_ids_to_request_data_for]

    logging.info(f"Found {len(users_to_request_data_for)} registered users who need their data updated. Sending messages to queue {scheduler_queue_url} in batches of {scheduler_queue_batch_size}")

    scheduler_queue.send_messages(objects=users_to_request_data_for, to_string=lambda user : user.to_json())

    for user in users_to_request_data_for:
        logging.info(f"Requested data for user {user.get_user_id()}")
        users_store.data_requested(user.get_user_id())

except UsersStoreException as e:
    logging.error("Unable to talk to our users store. Exiting.", e)
    sys.exit()

logging.info("Ended looking for users who haven't been updated in a while")

#
# Process any scheduler response messages. If they contain a list of neighbors to request data for, then request those as well
#

logging.info("Beginning processing scheduler response messages")

try:

    for queue_message in scheduler_response_queue:
        response = SchedulerResponseQueueItem.from_json(queue_message.get_message_body())

        logging.info(f"Received response message: User ID: {response.get_user_id()}, is registered user: {str(response.get_is_registered_user())}")

        neighbors_to_request_data_for = [SchedulerQueueItem(user_id=user_id, is_registered_user=False) for user_id in response.get_neighbor_list()]

        logging.info(f"Found {len(neighbors_to_request_data_for)} neighbors who need their data updated. Sending messages to queue {scheduler_queue_url} in batches of {scheduler_queue_batch_size}")

        scheduler_queue.send_messages(objects=neighbors_to_request_data_for, to_string=lambda user : user.to_json())

        for neighbor in neighbors_to_request_data_for:
            logging.info(f"Requested data for user {neighbor.get_user_id()}")

        users_store.data_updated(response.get_user_id())

        scheduler_response_queue.finished_with_message(queue_message)

except UsersStoreException as e:
    logging.error("Unable to talk to our users store. Exiting.", e)
    sys.exit()

finally:
    scheduler_response_queue.shutdown()

logging.info("Ended processing scheduler response messages")

#
# And we're finished
#

logging.info("Scheduler successfully completed processing")