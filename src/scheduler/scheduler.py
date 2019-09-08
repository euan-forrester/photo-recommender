#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
import time
from queuewriter import SQSQueueWriter
from queuereader import SQSQueueReader
from confighelper import ConfigHelper
from metricshelper import MetricsHelper
from unhandledexceptionhelper import UnhandledExceptionHelper
from pullerqueueitem import PullerQueueItem
from pullerresponsequeueitem import PullerResponseQueueItem
from usersstoreapiserver import UsersStoreAPIServer
from usersstoreexception import UsersStoreException
from executionenvironmenthelper import ExecutionEnvironmentHelper

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

scheduler_seconds_between_user_data_updates = config_helper.getInt("seconds-between-user-data-updates")

max_iterations_before_exit          = config_helper.getInt("max-iterations-before-exit")
sleep_ms_between_iterations         = config_helper.getInt("sleep-ms-between-iterations")

duration_to_request_lock_seconds    = config_helper.getInt("duration-to-request-lock-seconds")

#
# Metrics and unhandled exceptions
#

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="scheduler", metrics_namespace=metrics_namespace)
unhandled_exception_helper  = UnhandledExceptionHelper.setup_unhandled_exception_handler(metrics_helper=metrics_helper)

#
# Initialize our users' store
# 

users_store = UsersStoreAPIServer(host=api_server_host, port=api_server_port)

#
# Request permission to begin processing. We will frequently have several copies of this image running concurrently (for redundancy across
# availability zones, and when deploying new versions) but only one can be active at a given time. That's because if there
# were multiple copies all acting at once, several of them might see the same user(s) who haven't been updated in a while, and thus
# request multiple copies of their data.
#

try:

    execution_environment_helper = ExecutionEnvironmentHelper.get()

    task_id = execution_environment_helper.get_task_id()

    logging.info(f"We are currently running as task {task_id}. Requesting lock.")

    lock_acquired = users_store.request_lock("scheduler", task_id, duration_to_request_lock_seconds)

    if not lock_acquired:
        logging.info("Unable to acquire lock to begin processing. Exiting.")
        sys.exit(0)

    logging.info("Successfully acquired lock")

except UsersStoreException as e:
    logging.error("Unable to talk to our users store. Exiting.", e)
    metrics_helper.increment_count("UsersStoreException")
    sys.exit()

#
# Now that we have permission to continue processing, initialize our queue
# 


puller_queue = SQSQueueWriter(puller_queue_url, puller_queue_batch_size, metrics_helper)

#
# Begin by requesting all of the users that haven't been updated in a while
#

num_iterations = 0

while lock_acquired:

    logging.info("Beginning looking for users who haven't been updated in a while")

    try:
        users_ids_to_request_data_for = users_store.get_users_to_request_data_for(scheduler_seconds_between_user_data_updates)

        logging.info(f"Found {len(users_ids_to_request_data_for)} registered users who need their data updated. Sending messages to queue {puller_queue_url} in batches of {puller_queue_batch_size}")

        puller_requests = []

        for user_id in users_ids_to_request_data_for:

            # We can't necessarily fit a user's favorites + their contacts in a single message to the ingester queue, so split them up. 
            # A user's favorites barely fit as is, and also that'll let us request the two datasets concurrently in 2 processes, 
            # rather than one then the other in a single process

            puller_requests_for_user = []

            puller_requests_for_user.append(PullerQueueItem(user_id=user_id, initial_requesting_user_id=user_id, request_favorites=True, request_contacts=False, request_neighbor_list=True))
            puller_requests_for_user.append(PullerQueueItem(user_id=user_id, initial_requesting_user_id=user_id, request_favorites=False, request_contacts=True, request_neighbor_list=False))

            logging.info(f"Requesting data for user {user_id}")
            users_store.data_requested(user_id, len(puller_requests_for_user))

            puller_requests.extend(puller_requests_for_user)

        puller_queue.send_messages(objects=puller_requests, to_string=lambda request : request.to_json())

    except UsersStoreException as e:
        logging.error("Unable to talk to our users store. Exiting.", e)
        metrics_helper.increment_count("UsersStoreException")
        sys.exit()

    logging.info("Ended looking for users who haven't been updated in a while")

    #
    # Make sure we can still keep processing. We re-acquire our lock after each iteration to keep extending the lock end time.
    # We don't want to simply have a lock end time far in the future after the first attempt to acquire it, because if we
    # die later than another process won't be able to take over until that lock expires.
    #

    num_iterations += 1

    if num_iterations > max_iterations_before_exit:
        logging.info(f"Max iterations of {max_iterations_before_exit} reached. Exiting.")
        break

    logging.info(f"Finished iteration {num_iterations} of {max_iterations_before_exit}. Sleeping for {sleep_ms_between_iterations} ms")

    time.sleep(sleep_ms_between_iterations / 1000.0)

    lock_acquired = users_store.request_lock("scheduler", task_id, duration_to_request_lock_seconds)

    if lock_acquired:
        logging.info("Successfully able to acquire lock again")
    else:
        logging.info("Unable to re-acquire lock. Exiting")

#
# And we're finished
#

logging.info("Scheduler successfully completed processing")