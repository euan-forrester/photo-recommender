#!/usr/bin/env python3

import configparser
from flickrapiwrapper import FlickrApiWrapper
import argparse
import logging
import os
import boto3

# Read in commandline arguments

parser = argparse.ArgumentParser(description="Pull favorites data from Flickr and send it to Kafka")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

# Get our config

flickr_api_key                      = None
flickr_api_secret                   = None
flickr_api_retries                  = None
flickr_api_max_favorites_per_call   = None
flickr_api_max_favorites_to_get     = None
flickr_user_id                      = None
memcached_location                  = None
memcached_ttl                       = None

if not "ENVIRONMENT" in os.environ:
    logging.info("Did not find ENVIRONMENT environment variable, running in development mode and loading config from config files.")

    CONFIG_FILE_ENVIRONMENT = "dev"

    config = configparser.ConfigParser()

    config.read("config/config.ini")
    config.read("config/secrets.ini")

    flickr_api_key                      = config.get(CONFIG_FILE_ENVIRONMENT, "flickr.api.key")
    flickr_api_secret                   = config.get(CONFIG_FILE_ENVIRONMENT, "flickr.api.secret")
    flickr_api_retries                  = config.getint(CONFIG_FILE_ENVIRONMENT, "flickr.api.retries") 
    flickr_api_max_favorites_per_call   = config.getint(CONFIG_FILE_ENVIRONMENT, "flickr.api.favorites.maxpercall")
    flickr_api_max_favorites_to_get     = config.getint(CONFIG_FILE_ENVIRONMENT, "flickr.api.favorites.maxtoget")
    flickr_user_id                      = config.get(CONFIG_FILE_ENVIRONMENT, "flickr.user.id")
    memcached_location                  = config.get(CONFIG_FILE_ENVIRONMENT, "memcached.location")
    memcached_ttl                       = config.getint(CONFIG_FILE_ENVIRONMENT, "memcached.ttl")

else:
    ENVIRONMENT = os.environ.get('ENVIRONMENT')

    logging.info("Found ENVIRONMENT environment variable containing '%s': assuming we're running in AWS and getting our parameters from the AWS Parameter Store" % (ENVIRONMENT))

    ssm = boto3.client('ssm') # Region is read from the AWS_DEFAULT_REGION env var

    flickr_api_key                      = ssm.get_parameter(Name='/%s/puller-flickr/flickr-api-key'                         % ENVIRONMENT)['Parameter']['Value']
    flickr_api_secret                   = ssm.get_parameter(Name='/%s/puller-flickr/flickr-secret-key'                      % ENVIRONMENT, WithDecryption=True)['Parameter']['Value']
    flickr_api_retries                  = int(ssm.get_parameter(Name='/%s/puller-flickr/flickr-api-retries'                 % ENVIRONMENT)['Parameter']['Value'])
    flickr_api_max_favorites_per_call   = int(ssm.get_parameter(Name='/%s/puller-flickr/flickr-api-favorites-max-per-call'  % ENVIRONMENT)['Parameter']['Value'])
    flickr_api_max_favorites_to_get     = int(ssm.get_parameter(Name='/%s/puller-flickr/flickr-api-favorites-max-to-get'    % ENVIRONMENT)['Parameter']['Value'])
    flickr_user_id                      = ssm.get_parameter(Name='/%s/puller-flickr/flickr-user-id'                         % ENVIRONMENT)['Parameter']['Value']
    memcached_location                  = ssm.get_parameter(Name='/%s/puller-flickr/memcached-location'                     % ENVIRONMENT)['Parameter']['Value']
    memcached_ttl                       = int(ssm.get_parameter(Name='/%s/puller-flickr/memcached-ttl'                      % ENVIRONMENT)['Parameter']['Value'])

    logging.info("Found flickr api key %s" % (flickr_api_key))
    logging.info("Found flickr api secret %s" % (flickr_api_secret))
    logging.info("Found memcached location %s" % (memcached_location))
    logging.info("Found memcached ttl %d" % (memcached_ttl))

# Call Flickr to my favorites, and the favorites of the users who created them

flickrapi = FlickrApiWrapper(flickr_api_key, flickr_api_secret, memcached_location, memcached_ttl, flickr_api_retries)

# To locate photos that the user may find interesting, we first build a set of "neighbors" to this user.
# A "neighbor" is someone who took a photo that the user favorited.
# We will then assign a score to each of these neighbors, and use those scores to assign scores to their favorite photos.
# The highest-scored of these photos will be shown to the original user.

logging.info("Getting my favourites")

my_favorites = flickrapi.get_favorites(flickr_user_id, flickr_api_max_favorites_per_call, flickr_api_max_favorites_to_get)
my_favorite_ids = set()
all_neighbor_favorite_photo_ids = {}

my_neighbors = {}

for photo in my_favorites:
    logging.debug("Found favourite photo ", photo)
    my_favorite_ids.add(photo['id'])
    if photo['owner'] not in my_neighbors:
        my_neighbors[photo['owner']] = { 'user_id': photo['owner'] }

logging.debug("Found neighbors: ", my_neighbors)

# To calculate the score of each neighbour we need to know its favourites

for neighbor_id in my_neighbors:

    my_neighbors[neighbor_id]['favorite_ids'] = set()

    logging.info("Getting favorites of neighbor %s" % (my_neighbors[neighbor_id]['user_id']))

    neighbor_favorites = flickrapi.get_favorites(my_neighbors[neighbor_id]['user_id'], flickr_api_max_favorites_per_call, flickr_api_max_favorites_to_get)

    for photo in neighbor_favorites:
        logging.debug("Found neighbor favourite photo ", photo)

        my_neighbors[neighbor_id]['favorite_ids'].add(photo['id'])
        all_neighbor_favorite_photo_ids[photo['id']] = { 'score': 0, 'image_url': photo.get('url_l', photo.get('url_m', '')), 'id': photo['id'], 'user': photo['owner'] }
