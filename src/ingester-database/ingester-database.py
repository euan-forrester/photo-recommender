#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
from ingesterqueueitem import IngesterQueueItem
from ingesterqueuebatchitem import IngesterQueueBatchItem
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

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="ingester-database")
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
    max_messages_to_read=input_queue_max_items_to_process)

database = DatabaseBatchWriter(
    username=output_database_username, 
    password=output_database_password, 
    host=output_database_host, 
    port=output_database_port, 
    database=output_database_name, 
    max_retries=output_database_max_retries)

photo_batch = []
unwritten_message_batch = []

def write_batch(photo_batch, unwritten_message_batch):

    if len(photo_batch) > 0:

        # INSERT IGNORE means to ignore any errors that occur while inserting, particularly key errors indicating duplicate entries.
        database.batch_write(
            "INSERT IGNORE INTO favorites (image_id, image_owner, image_url, favorited_by) VALUES (%s, %s, %s, %s)", 
            lambda photo: ( photo.get_image_id(), photo.get_image_owner(), photo.get_image_url(), photo.get_favorited_by() ),
            photo_batch
        )

        logging.info(f"Wrote out batch of {len(photo_batch)} messages to database")

        # Only delete our messages after we've successfully inserted them into the database.
        # Otherwise, if there's an error inserting, we want all of these messages to get re-driven so we can try again.
        # There shouldn't be any duplicates, because an error here will mean that the process has to quit and thus the 
        # database transaction won't be committed. But if there were any resultant duplicates they would just be ignored.
        for successful_message in unwritten_message_batch:
            queue.finished_with_message(successful_message)

for queue_message in queue:
    photo_batch_queue_item = IngesterQueueBatchItem.from_json(queue_message.get_message_body())

    logging.info(f"Received batch item containing {len(photo_batch_queue_item.get_item_list())} individual items")

    if logging.getLogger().getEffectiveLevel() <= logging.DEBUG:
        for photo in photo_batch_queue_item.get_item_list():
            logging.debug(f"Received item: image owner: {photo.get_image_owner()}, image ID: {photo.get_image_id()}, image URL: {photo.get_image_url()}, image favorited by: {photo.get_favorited_by()}")

    photo_batch.extend(photo_batch_queue_item.get_item_list())
    unwritten_message_batch.append(queue_message)

    if len(photo_batch) >= output_database_min_batch_size:

        write_batch(photo_batch, unwritten_message_batch)

        photo_batch = []
        unwritten_message_batch = []

# Write out any remaining items that didn't make a full batch
write_batch(photo_batch, unwritten_message_batch)

database.shutdown()
queue.shutdown()

logging.info("Successfully finished processing")