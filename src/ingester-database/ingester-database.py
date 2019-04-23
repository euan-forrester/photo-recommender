#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
import os
from ingesterqueueitem import IngesterQueueItem
from queuereader import SQSQueueReader
from confighelper import ConfigHelperFile
from confighelper import ConfigHelperParameterStore
from databasebatchwriter import DatabaseBatchWriter

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

if not "ENVIRONMENT" in os.environ:
    logging.info("Did not find ENVIRONMENT environment variable, running in development mode and loading config from config files.")

    ENVIRONMENT = "dev"

    config_helper = ConfigHelperFile(environment=ENVIRONMENT, filename_list=["config/config.ini", "config/secrets.ini"])

else:
    ENVIRONMENT = os.environ.get('ENVIRONMENT')

    logging.info("Found ENVIRONMENT environment variable containing '%s': assuming we're running in AWS and getting our parameters from the AWS Parameter Store" % (ENVIRONMENT))

    config_helper = ConfigHelperParameterStore(environment=ENVIRONMENT, key_prefix="ingester-database")

input_queue_url                     = config_helper.get("input-queue-url")
input_queue_batch_size              = config_helper.getInt("input-queue-batchsize")
input_queue_max_items_to_process    = config_helper.getInt("input-queue-maxitemstoprocess")

output_database_username            = config_helper.get("output-database-username")
output_database_password            = config_helper.get("output-database-password", is_secret=True)
output_database_host                = config_helper.get("output-database-host")
output_database_port                = config_helper.getInt("output-database-port")
output_database_name                = config_helper.get("output-database-name")
output_database_batch_size          = config_helper.getInt("output-database-batchsize")

#
# Receive some messages from the input queue and write them to the favorites database
#
# We only receive up to a maximum each time the process runs to prevent the process from running forever,
# and thus the difficult-to-reproduce problems that can come from long-running processes
#

queue = SQSQueueReader(queue_url=input_queue_url, batch_size=input_queue_batch_size, max_messages_to_read=input_queue_max_items_to_process)

database = DatabaseBatchWriter(username=output_database_username, password=output_database_password, host=output_database_host, port=output_database_port, database=output_database_name)

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

        logging.info("Wrote out batch of %d messages to database" % len(photo_batch))

        # Only delete our messages after we've successfully inserted them into the database.
        # Otherwise, if there's an error inserting, we want all of these messages to get re-driven so we can try again.
        # There shouldn't be any duplicates, because an error here will mean that the process has to quit and thus the 
        # database transaction won't be committed. But if there were any resultant duplicates they would just be ignored.
        for successful_message in unwritten_message_batch:
            queue.finished_with_message(successful_message)

for queue_message in queue:
    photo = IngesterQueueItem.from_json(queue_message.get_message_body())

    logging.info("Received message: Image owner: %s, image ID: %s, image URL: %s, image favorited by: %s" % (photo.get_image_owner(), photo.get_image_id(), photo.get_image_url(), photo.get_favorited_by()))

    photo_batch.append(photo)
    unwritten_message_batch.append(queue_message)

    if len(photo_batch) >= output_database_batch_size:

        write_batch(photo_batch, unwritten_message_batch)

        photo_batch = []
        unwritten_message_batch = []

# Write out any remaining items that didn't make a full batch
write_batch(photo_batch, unwritten_message_batch)

database.shutdown()
queue.shutdown()