#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
import time
from ingesterqueuefavorite import IngesterQueueFavorite
from ingesterqueuebatchitem import IngesterQueueBatchItem
from contactitem import ContactItem
from queuereader import SQSQueueReader
from confighelper import ConfigHelper
from databasebatchwriter import DatabaseBatchWriter
from metricshelper import MetricsHelper
from unhandledexceptionhelper import UnhandledExceptionHelper

#
# Read in commandline arguments
#

parser = argparse.ArgumentParser(description="Pull data from the ingestion queue and write it to the favorites database")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="ingester-database")

metrics_namespace                   = config_helper.get("metrics-namespace")

input_queue_url                     = config_helper.get("input-queue-url")
input_queue_batch_size              = config_helper.getInt("input-queue-batchsize")
input_queue_max_items_to_process    = config_helper.getInt("input-queue-maxitemstoprocess")

output_database_username            = config_helper.get("output-database-username")
output_database_password            = config_helper.get("output-database-password", is_secret=True)
output_database_host                = config_helper.get("output-database-host")
output_database_port                = config_helper.getInt("output-database-port")
output_database_name                = config_helper.get("output-database-name")
output_database_min_batch_size      = config_helper.getInt("output-database-min-batchsize")
output_database_max_retries         = config_helper.getInt("output-database-maxretries")

#
# Metrics and unhandled exceptions
#

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="ingester-database", metrics_namespace=metrics_namespace)
unhandled_exception_helper  = UnhandledExceptionHelper.setup_unhandled_exception_handler(metrics_helper=metrics_helper)

#
# Receive some messages from the input queue and write them to the favorites database
#
# We only receive up to a maximum each time the process runs to prevent the process from running forever,
# and thus the difficult-to-reproduce problems that can come from long-running processes
#

queue = SQSQueueReader(
    queue_url=input_queue_url, 
    batch_size=input_queue_batch_size, 
    max_messages_to_read=input_queue_max_items_to_process,
    metrics_helper=metrics_helper)

database = DatabaseBatchWriter(
    username=output_database_username, 
    password=output_database_password, 
    host=output_database_host, 
    port=output_database_port, 
    database=output_database_name, 
    max_retries=output_database_max_retries,
    metrics_helper=metrics_helper)

favorites_batch = []
contacts_batch = []
read_message_batch = []

def write_favorites_batch(favorites_batch):

    if len(favorites_batch) > 0:

        begin_database_write = time.perf_counter()

        # INSERT IGNORE means to ignore any errors that occur while inserting, particularly key errors indicating duplicate entries.
        database.batch_write(
            "INSERT IGNORE INTO favorites (image_id, image_owner, image_url, favorited_by) VALUES (%s, %s, %s, %s)", 
            lambda photo: ( photo.get_image_id(), photo.get_image_owner(), photo.get_image_url(), photo.get_favorited_by() ),
            favorites_batch
        )

        end_database_write = time.perf_counter()

        database_write_duration = end_database_write - begin_database_write

        metrics_helper.send_time("database_favorites_write_duration", database_write_duration)

        logging.info(f"Wrote out batch of {len(favorites_batch)} favorites to database. Took {database_write_duration} seconds.")

def write_contacts_batch(contacts_batch):

    if len(contacts_batch) > 0:

        begin_database_write = time.perf_counter()

        # INSERT IGNORE means to ignore any errors that occur while inserting, particularly key errors indicating duplicate entries.
        database.batch_write(
            "INSERT IGNORE INTO followers (follower_id, followee_id) VALUES (%s, %s)", 
            lambda contact: ( contact.get_follower_id(), contact.get_followee_id() ),
            contacts_batch
        )

        end_database_write = time.perf_counter()

        database_write_duration = end_database_write - begin_database_write

        metrics_helper.send_time("database_contacts_write_duration", database_write_duration)

        logging.info(f"Wrote out batch of {len(contacts_batch)} contacts to database. Took {database_write_duration} seconds.")

def commit_batches(favorites_batch, contacts_batch, database, read_message_batch):
    write_favorites_batch(favorites_batch)
    write_contacts_batch(contacts_batch)
    
    database.commit_current_batches()

    # Only delete our messages after we've successfully committed them into the database.
    # Otherwise, if there's an error inserting, we want all of these messages to get re-driven so we can try again.
    # There shouldn't be any duplicates, because an error here will mean that the process has to quit and thus the 
    # database transaction won't be committed. But if there were any resultant duplicates they would just be ignored.
    for successful_message in read_message_batch:
        queue.finished_with_message(successful_message)

for queue_message in queue:

    begin_process_batch_message = time.perf_counter()

    batch_queue_item = IngesterQueueBatchItem.from_json(queue_message.get_message_body())

    logging.info(f"Received batch item for user {batch_queue_item.get_user_id()} containing {len(batch_queue_item.get_favorites_list())} favorites and {len(batch_queue_item.get_contacts_list())} contacts")

    if logging.getLogger().getEffectiveLevel() <= logging.DEBUG:
        for favorite in batch_queue_item.get_favorites_list():
            logging.debug(f"Received favorite: image owner: {favorite.get_image_owner()}, image ID: {favorite.get_image_id()}, image URL: {favorite.get_image_url()}, image favorited by: {favorite.get_favorited_by()}")

        for contact_user_id in batch_queue_item.get_contacts_list():
            logging.debug(f"Received contact for user {batch_queue_item.get_user_id()}: {contact_user_id}")

    favorites_batch.extend(batch_queue_item.get_favorites_list())
    contacts_batch.extend([ContactItem(batch_queue_item.get_user_id(), followee_id) for followee_id in batch_queue_item.get_contacts_list()]) # Don't include these ContactItems in the actual message, because they're bloated with the follower_id over and over. But we need them here because we're inserting items as a batch, and different items may have different follower_ids
    read_message_batch.append(queue_message)

    if (len(favorites_batch) >= output_database_min_batch_size) or (len(contacts_batch) >= output_database_min_batch_size):
        commit_batches(favorites_batch, contacts_batch, database, read_message_batch);
        favorites_batch = []
        contacts_batch = []
        read_message_batch = []

    end_process_batch_message = time.perf_counter()

    process_batch_message_duration = end_process_batch_message - begin_process_batch_message
    logging.info(f"Took {process_batch_message_duration} seconds to process batch message")

# Write out any remaining items that didn't make a full batch
commit_batches(favorites_batch, contacts_batch, database, read_message_batch)

database.shutdown()
queue.shutdown()

logging.info("Successfully finished processing")