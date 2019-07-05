#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

from flickrapiwrapper import FlickrApiWrapper
import argparse
import logging
from ingesterqueueitem import IngesterQueueItem
from schedulerqueueitem import SchedulerQueueItem
from schedulerresponsequeueitem import SchedulerResponseQueueItem
from queuewriter import SQSQueueWriter
from queuereader import SQSQueueReader
from confighelper import ConfigHelper

#
# Read in commandline arguments
#

parser = argparse.ArgumentParser(description="Pull favorites data from Flickr and send it to SQS")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="puller-flickr")

flickr_api_key                      = config_helper.get("flickr-api-key")
flickr_api_secret                   = config_helper.get("flickr-api-secret", is_secret=True)
flickr_api_retries                  = config_helper.getInt("flickr-api-retries") 
flickr_api_max_favorites_per_call   = config_helper.getInt("flickr-api-favorites-maxpercall")
flickr_api_max_favorites_to_get     = config_helper.getInt("flickr-api-favorites-maxtoget")

memcached_location                  = config_helper.get("memcached-location")
memcached_ttl                       = config_helper.getInt("memcached-ttl")

output_queue_url                    = config_helper.get("output-queue-url")
output_queue_batch_size             = config_helper.getInt("output-queue-batchsize")

scheduler_response_queue_url        = config_helper.get("scheduler-response-queue-url")

scheduler_queue_url                 = config_helper.get("scheduler-queue-url")
scheduler_queue_batch_size          = config_helper.getInt("scheduler-queue-batchsize")
scheduler_queue_max_items_to_process = config_helper.getInt("scheduler-queue-maxitemstoprocess")

flickrapi = FlickrApiWrapper(flickr_api_key, flickr_api_secret, memcached_location, memcached_ttl, flickr_api_retries, flickr_api_max_favorites_per_call, flickr_api_max_favorites_to_get)

scheduler_queue             = SQSQueueReader(queue_url=scheduler_queue_url,             batch_size=scheduler_queue_batch_size, max_messages_to_read=scheduler_queue_max_items_to_process)
scheduler_response_queue    = SQSQueueWriter(queue_url=scheduler_response_queue_url,    batch_size=1) # We ignore the batch size by sending the messages one at a time, because we don't want to miss any if we have an error
output_queue                = SQSQueueWriter(queue_url=output_queue_url,                batch_size=output_queue_batch_size)

def process_user(scheduler_queue_item):

    # We will need to build a set of "neighbors" to our user. A "neighbor" is someone who took a photo that the user favorited.
    # We will use each neighbor's photos to assign a score to that neighbor, which we will then use to assign a score to each of their favorites.

    # The Scheduler will request all of the favorites of each neighbor, but we need to provide it the actual list of neighbors.
    # That's because it might be a while before the ingester_database process finishes ingesting the data we just pulled here, so the Scheduler
    # won't be able to find out the list of neighbors from the database until an unspecified time in the future

    flickr_user_id      = scheduler_queue_item.get_user_id()
    is_registered_user  = scheduler_queue_item.get_is_registered_user()

    logging.info(f"Getting favourites for requested user {flickr_user_id}")

    my_favorites = flickrapi.get_favorites(flickr_user_id)
    favorite_photos = []

    my_neighbors = set()

    for photo in my_favorites:
        logging.debug("Found photo I favorited: ", photo)
        
        favorite_photos.append(IngesterQueueItem(favorited_by=flickr_user_id, image_id=photo['id'], image_url=photo.get('url_l', photo.get('url_m', '')), image_owner=photo['owner']))

        my_neighbors.add(photo['owner'])

    my_neighbors_list = list(my_neighbors)

    logging.debug("Found list of neighbors: ", my_neighbors_list)

    # Output all of the photos we found to our output queue so they can be ingested into the database

    logging.info(f"Found {len(favorite_photos)} photos to send to queue {output_queue_url} in batches of {output_queue_batch_size}")

    output_queue.send_messages(objects=favorite_photos, to_string=lambda photo : photo.to_json())

    # And send a response to the scheduler saying that we've successfully processed this request

    if not is_registered_user:
        my_neighbors_list = [] # The Scheduler doesn't care about neighbors of neighbors, so if this isn't a registered user then don't bother to send them. They'll just be a bunch of data for no reason, and might exceed the max and cause unnecessary trouble

    scheduler_response_queue_item = SchedulerResponseQueueItem(user_id=flickr_user_id, is_registered_user=is_registered_user, neighbor_list=my_neighbors_list) 

    if scheduler_response_queue_item.get_max_neighbors_exceeded():
        logging.warn(f"User {flickr_user_id} exceeded max number of neighbors: has {len(my_neighbors_list)} neighbors. Consider putting this list is S3 rather than in this SQS message")
        # FIXME: Increment a metric here so that we can alert on this

    scheduler_response_queue.send_messages(objects=[scheduler_response_queue_item], to_string=lambda x: x.to_json()) # Sends messages one at a time, regardless of what the batch size is set to. We don't want to batch them up then miss sending one if we have an error later

    logging.info(f"Finished processing for requested user {flickr_user_id}")

#
# Call Flickr to get my favorites, and the favorites of the users who created them
#

logging.info(f"About to query queue {scheduler_queue_url} for requests")

try:

    for queue_message in scheduler_queue:
        scheduler_queue_item = SchedulerQueueItem.from_json(queue_message.get_message_body())

        process_user(scheduler_queue_item)

        scheduler_queue.finished_with_message(queue_message)

finally:
    scheduler_queue.shutdown()

logging.info("Successfully finished processing")