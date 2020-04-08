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
min_sleep_ms_between_iterations     = config_helper.getInt("min-sleep-ms-between-iterations")

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

            puller_requests_for_user = PullerQueueItem.get_messages_to_request_all_data_for_user(user_id)

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

    # Figure out how long to sleep based on how long it is until we request data for the next user

    try:

        seconds_to_sleep = 0

        max_seconds_since_last_update = users_store.get_max_seconds_since_last_update()

        # If we got back a number < 0, it means we have no users. So just sleep for a while. Any new users will have
        # their data requested when they are created, so we're guaranteed not to miss their next update if we sleep
        # for the number of seconds between updates
        if max_seconds_since_last_update < 0:
            seconds_to_sleep = scheduler_seconds_between_user_data_updates

        seconds_to_sleep = max(scheduler_seconds_between_user_data_updates - max_seconds_since_last_update, min_sleep_ms_between_iterations / 1000.0) + 1.0 # Sleep an extra second so we're sure to pick up the users when we wake up, rather than just missing them due to some imprecision in the length of time we sleep

        seconds_to_lock_while_sleeping = seconds_to_sleep + duration_to_request_lock_seconds

        logging.info(f"Finished iteration {num_iterations} of {max_iterations_before_exit}")
        logging.info(f"Max seconds since a user was updated: {max_seconds_since_last_update}. Desired seconds between user updates: {scheduler_seconds_between_user_data_updates}. Requesting lock for {seconds_to_lock_while_sleeping} seconds so we can sleep for {seconds_to_sleep} seconds")

        # We need to extend our lock while we sleep. Otherwise another scheduler process will acquire the lock, find no users to update, and then
        # sleep. Until all the processes are sleeping for a long time. Having all of our redundant schedulers asleep doesn't really help us.
        # So we'll keep the lock on this process so that the others are still awake and able to take over if this one dies

        lock_acquired_to_sleep = users_store.request_lock("scheduler", task_id, seconds_to_lock_while_sleeping)

        if lock_acquired_to_sleep:
            logging.info("Successfully able to acquire lock to sleep.")
        else:
            logging.info("Unable to re-acquire lock to sleep. Exiting")
            break

        logging.info(f"Sleeping for {seconds_to_sleep} seconds")

        time.sleep(seconds_to_sleep)

    except UsersStoreException as e:
        logging.error("Unable to talk to our users store. Exiting.", e)
        metrics_helper.increment_count("UsersStoreException")
        sys.exit()

    # We've woken up again, so now try to re-acquire our lock

    logging.info("Woke up, trying to acquire lock again")

    lock_acquired = users_store.request_lock("scheduler", task_id, duration_to_request_lock_seconds)

    if lock_acquired:
        logging.info("Successfully able to acquire lock again")
    else:
        logging.info("Unable to re-acquire lock. Exiting")

#
# And we're finished
#

logging.info("Scheduler successfully completed processing")