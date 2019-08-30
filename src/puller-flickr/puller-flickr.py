#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

from flickrapiwrapper import FlickrApiWrapper
import argparse
import logging
import time
from ingesterqueueitem import IngesterQueueItem
from ingesterqueuebatchitem import IngesterQueueBatchItem
from pullerqueueitem import PullerQueueItem
from pullerresponsequeueitem import PullerResponseQueueItem
from queuewriter import SQSQueueWriter
from queuereader import SQSQueueReader
from confighelper import ConfigHelper
from metricshelper import MetricsHelper
from unhandledexceptionhelper import UnhandledExceptionHelper

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

metrics_namespace                   = config_helper.get("metrics-namespace")

flickr_api_key                      = config_helper.get("flickr-api-key")
flickr_api_secret                   = config_helper.get("flickr-api-secret", is_secret=True)
flickr_api_retries                  = config_helper.getInt("flickr-api-retries") 
flickr_api_max_favorites_per_call   = config_helper.getInt("flickr-api-favorites-maxpercall")
flickr_api_max_favorites_to_get     = config_helper.getInt("flickr-api-favorites-maxtoget")
flickr_api_max_calls_to_make        = config_helper.getInt("flickr-api-favorites-maxcallstomake")

memcached_location                  = config_helper.get("memcached-location")
memcached_ttl                       = config_helper.getInt("memcached-ttl")

output_queue_url                    = config_helper.get("output-queue-url")
output_queue_batch_size             = config_helper.getInt("output-queue-batchsize")

puller_response_queue_url           = config_helper.get("puller-response-queue-url")

puller_queue_url                    = config_helper.get("puller-queue-url")
puller_queue_batch_size             = config_helper.getInt("puller-queue-batchsize")
puller_queue_max_items_to_process   = config_helper.getInt("puller-queue-maxitemstoprocess")

#
# Metrics and unhandled exceptions
#

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="puller-flickr", metrics_namespace=metrics_namespace)
unhandled_exception_helper  = UnhandledExceptionHelper.setup_unhandled_exception_handler(metrics_helper=metrics_helper)

#
# Set up our API wrapper and queues
#

flickrapi = FlickrApiWrapper(
    flickr_api_key, 
    flickr_api_secret, 
    memcached_location, 
    memcached_ttl, 
    flickr_api_retries, 
    metrics_helper)

puller_queue            = SQSQueueReader(queue_url=puller_queue_url,            batch_size=puller_queue_batch_size, max_messages_to_read=puller_queue_max_items_to_process,   metrics_helper=metrics_helper)
puller_response_queue   = SQSQueueWriter(queue_url=puller_response_queue_url,   batch_size=1,                                                                                       metrics_helper=metrics_helper) # We ignore the batch size by sending the messages one at a time, because we don't want to miss any if we have an error
output_queue            = SQSQueueWriter(queue_url=output_queue_url,            batch_size=output_queue_batch_size,                                                                 metrics_helper=metrics_helper)

#
# Process items from our input queue
#

def process_user(puller_queue_item):

    # We will need to build a set of "neighbors" to our user. A "neighbor" is someone who took a photo that the user favorited.
    # We will use each neighbor's photos to assign a score to that neighbor, which we will then use to assign a score to each of their favorites.

    # The Scheduler will request all of the favorites of each neighbor, but we need to provide it the actual list of neighbors.
    # That's because it might be a while before the ingester_database process finishes ingesting the data we just pulled here, so the Scheduler
    # won't be able to find out the list of neighbors from the database until an unspecified time in the future

    begin_process_user = time.perf_counter()

    flickr_user_id      = puller_queue_item.get_user_id()
    is_registered_user  = puller_queue_item.get_is_registered_user()

    logging.info(f"Getting favourites for requested user {flickr_user_id}")

    begin_query_flickr = time.perf_counter()
    my_favorites = flickrapi.get_favorites(flickr_user_id, flickr_api_max_favorites_per_call, flickr_api_max_favorites_to_get, flickr_api_max_calls_to_make)
    end_query_flickr = time.perf_counter()

    favorite_photos = []

    my_neighbors = set()

    for photo in my_favorites:
        logging.debug("Found photo I favorited: ", photo)
        
        favorite_photos.append(IngesterQueueItem(favorited_by=flickr_user_id, image_id=photo['id'], image_url=photo.get('url_l', photo.get('url_m', '')), image_owner=photo['owner']))

        my_neighbors.add(photo['owner'])

    my_neighbors_list = list(my_neighbors)

    logging.debug("Found list of neighbors: ", my_neighbors_list)

    # Output all of the photos we found to our output queue so they can be ingested into the database

    logging.info(f"Found {len(favorite_photos)} photos to send to queue {output_queue_url} in one batch item")

    if len(favorite_photos) > 0:

        batch_item = IngesterQueueBatchItem(favorite_photos) # There's a max of 256kB per message in SQS, and with 1000 photos our message bodies come in around 218kB. Will need to split them up if we get > 1000 photos/user

        if batch_item.get_max_items_exceeded():
            logging.warn(f"User {flickr_user_id} exceeded max number of batched favorite photos: has {len(favorite_photos)} favorites. Consider putting this list is S3 rather than in this SQS message")
            metrics_helper.increment_count("MaxBatchSizeExceeded")

        output_queue.send_messages(objects=[batch_item], to_string=lambda x : x.to_json())

    else:
        logging.info("Not sending a message because we didn't find any photos")

    # And send a response to the scheduler saying that we've successfully processed this request

    if not is_registered_user:
        my_neighbors_list = [] # The Scheduler doesn't care about neighbors of neighbors, so if this isn't a registered user then don't bother to send them. They'll just be a bunch of data for no reason, and might exceed the max and cause unnecessary trouble

    puller_response_queue_item = PullerResponseQueueItem(user_id=flickr_user_id, is_registered_user=is_registered_user, neighbor_list=my_neighbors_list) 

    if puller_response_queue_item.get_max_neighbors_exceeded():
        logging.warn(f"User {flickr_user_id} exceeded max number of neighbors: has {len(my_neighbors_list)} neighbors. Consider putting this list is S3 rather than in this SQS message")
        metrics_helper.increment_count("MaxNeighborsExceeded")

    puller_response_queue.send_messages(objects=[puller_response_queue_item], to_string=lambda x: x.to_json()) # Sends messages one at a time, regardless of what the batch size is set to. We don't want to batch them up then miss sending one if we have an error later

    end_process_user = time.perf_counter()

    duration_to_process_user = end_process_user - begin_process_user
    duration_to_query_flickr = end_query_flickr - begin_query_flickr

    metrics_helper.send_time("duration_to_process_user", duration_to_process_user)
    metrics_helper.send_time("duration_to_query_flickr", duration_to_query_flickr)

    logging.info(f"Finished processing for requested user {flickr_user_id}. Took {duration_to_process_user} seconds, of which {duration_to_query_flickr} seconds was spent querying Flickr")

#
# Call Flickr to get my favorites, and the favorites of the users who created them
#

logging.info(f"About to query queue {puller_queue_url} for requests")

try:

    for queue_message in puller_queue:
        puller_queue_item = PullerQueueItem.from_json(queue_message.get_message_body())

        process_user(puller_queue_item)

        puller_queue.finished_with_message(queue_message)

finally:
    puller_queue.shutdown()

logging.info("Successfully finished processing")