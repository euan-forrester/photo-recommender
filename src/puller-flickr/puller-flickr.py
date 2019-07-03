#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

from flickrapiwrapper import FlickrApiWrapper
import argparse
import logging
from ingesterqueueitem import IngesterQueueItem
from queuewriter import SQSQueueWriter
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

flickr_user_id                      = config_helper.get("flickr-user-id")
flickr_api_key                      = config_helper.get("flickr-api-key")
flickr_api_secret                   = config_helper.get("flickr-api-secret", is_secret=True)
flickr_api_retries                  = config_helper.getInt("flickr-api-retries") 
flickr_api_max_favorites_per_call   = config_helper.getInt("flickr-api-favorites-maxpercall")
flickr_api_max_favorites_to_get     = config_helper.getInt("flickr-api-favorites-maxtoget")
memcached_location                  = config_helper.get("memcached-location")
memcached_ttl                       = config_helper.getInt("memcached-ttl")
output_queue_url                    = config_helper.get("output-queue-url")
output_queue_batch_size             = config_helper.getInt("output-queue-batchsize")

#
# Call Flickr to get my favorites, and the favorites of the users who created them
#

flickrapi = FlickrApiWrapper(flickr_api_key, flickr_api_secret, memcached_location, memcached_ttl, flickr_api_retries)

# We will need to build a set of "neighbors" to our user. A "neighbor" is someone who took a photo that the user favorited.
# We will use each neighbor's photos to assign a score to that neighbor, which we will then use to assign a score to each of their favorites.

logging.info("Getting my favourites")

my_favorites = flickrapi.get_favorites(flickr_user_id, flickr_api_max_favorites_per_call, flickr_api_max_favorites_to_get)
favorite_photos = []

my_neighbors = {}

for photo in my_favorites:
    logging.debug("Found photo I favorited: ", photo)
    
    favorite_photos.append(IngesterQueueItem(favorited_by=flickr_user_id, image_id=photo['id'], image_url=photo.get('url_l', photo.get('url_m', '')), image_owner=photo['owner']))

    if photo['owner'] not in my_neighbors:
        my_neighbors[photo['owner']] = { 'user_id': photo['owner'] }

logging.debug("Found list of neighbors: ", my_neighbors)

# To calculate the score of each neighbour we need to know its favourites
for neighbor_id in my_neighbors:

    logging.info("Getting favorites of neighbor %s" % (my_neighbors[neighbor_id]['user_id']))

    neighbor_favorites = flickrapi.get_favorites(my_neighbors[neighbor_id]['user_id'], flickr_api_max_favorites_per_call, flickr_api_max_favorites_to_get)

    for photo in neighbor_favorites:
        logging.debug("Found neighbor favourite photo ", photo)

        favorite_photos.append(IngesterQueueItem(favorited_by=my_neighbors[neighbor_id]['user_id'], image_id=photo['id'], image_url=photo.get('url_l', photo.get('url_m', '')), image_owner=photo['owner']))

#
# Output all of the photos we found to our queue
#

logging.info("Found %d photos to send to queue %s in batches of %d" % (len(favorite_photos), output_queue_url, output_queue_batch_size))

queue = SQSQueueWriter(output_queue_url, output_queue_batch_size)

queue.send_messages(objects=favorite_photos, to_string=lambda photo : photo.to_json())

logging.info("Successfully finished processing")