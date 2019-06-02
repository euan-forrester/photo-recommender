#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
import atexit
from flask import Flask
from flask import request
from flask_api import status
from confighelper import ConfigHelper
from favoritesstoredatabase import FavoritesStoreDatabase
from favoritesstoreexception import FavoritesStoreException
from recommendations import Recommendations
from output import Output

#
# Read in commandline arguments
#

parser = argparse.ArgumentParser(description="Serve API requests from the favorites database")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args, _ = parser.parse_known_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="api-server")

database_username           = config_helper.get("database-username")
database_password           = config_helper.get("database-password", is_secret=True)
database_host               = config_helper.get("database-host")
database_port               = config_helper.getInt("database-port")
database_name               = config_helper.get("database-name")
database_fetch_batch_size   = config_helper.getInt("database-fetch-batch-size")
server_host                 = config_helper.get("server-host")
server_port                 = config_helper.getInt("server-port")
default_num_photo_recommendations = config_helper.getInt('default-num-photo-recommendations')

#
# Set up our data store
#

favorites_store = FavoritesStoreDatabase(
    database_username=database_username, 
    database_password=database_password, 
    database_host=database_host, 
    database_port=database_port, 
    database_name=database_name, 
    fetch_batch_size=database_fetch_batch_size)

def cleanup_data_store():
    favorites_store.shutdown()

atexit.register(cleanup_data_store)

#
# Run our API server
#
# Note that the Flask built-in server is not sufficient for production. In production we run under gunicorn instead, and
# we run behind an AWS Application Load Balancer. See: 
#   https://medium.com/@kmmanoj/deploying-a-scalable-flask-app-using-gunicorn-and-nginx-in-docker-part-1-3344f13c9649
#

application = Flask(__name__)

@application.route("/healthcheck")
def health_check():
    return "OK", status.HTTP_200_OK

@application.route("/users/<user_id>/recommendations-fast")
def get_recommendations_fast(user_id=None):
    if user_id is None:
        return "User not specified", status.HTTP_400_BAD_REQUEST

    num_photos = int(request.args.get('num-photos', default_num_photo_recommendations))

    recommendations = favorites_store.get_photo_recommendations(user_id, num_photos)

    output = Output.get_output(recommendations)

    return output

@application.route("/users/<user_id>/recommendations")
def get_recommendations(user_id=None):
    if user_id is None:
        return "User not specified", status.HTTP_400_BAD_REQUEST

    num_photos = int(request.args.get('num-photos', default_num_photo_recommendations))

    all_favorites = favorites_store.get_my_favorites_and_neighbors_favorites(user_id)

    recommendations = Recommendations.get_recommendations(user_id, all_favorites, num_photos)

    output = Output.get_output(recommendations)

    return output

if __name__ == '__main__':
    # Note that running Flask like this results in the output saying "lazy loading" and I'm not sure what that means.
    # If we run it the way specified in the documentation `FLASK_APP=./api-server.py flask run` then it doesn't say this.
    # But I wanted to be able to specify the port via a parameter rather than having to use an env var
    application.run(host=server_host, port=server_port)