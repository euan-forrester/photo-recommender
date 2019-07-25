#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
import atexit
from flask import Flask
from flask import request
from flask import jsonify
from flask_api import status
from confighelper import ConfigHelper
from favoritesstoredatabase import FavoritesStoreDatabase
from favoritesstoreexception import FavoritesStoreException
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
database_connection_pool_size = config_helper.getInt("database-connection-pool-size")
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
    fetch_batch_size=database_fetch_batch_size,
    connection_pool_size=database_connection_pool_size)

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

# Health check for our load balancer
@application.route("/healthcheck", methods = ['GET'])
def health_check():
    return "OK", status.HTTP_200_OK

# Gets our recommendations for a specific user
@application.route("/users/<user_id>/recommendations", methods = ['GET'])
def get_recommendations(user_id=None):
    if user_id is None:
        return user_not_specified()

    num_photos = int(request.args.get('num-photos', default_num_photo_recommendations))

    recommendations = favorites_store.get_photo_recommendations(user_id, num_photos)

    output = Output.get_output(recommendations)

    return output, status.HTTP_200_OK

# Gets a list of registered users who need to have their data refreshed
@application.route("/users/need-update", methods = ['GET'])
def get_users_that_need_update():

    num_seconds_between_updates = request.args.get('num-seconds-between-updates')

    if not num_seconds_between_updates:
        return parameter_not_specified("num-seconds-between-updates")

    users = favorites_store.get_users_that_need_updated(int(num_seconds_between_updates))

    resp = jsonify(users)
    resp.status_code = status.HTTP_200_OK

    return resp

# Gets a list of registered users who are currently in the process of having their data refreshed
@application.route("/users/currently-updating", methods = ['GET'])
def get_users_that_are_currently_updating():

    users = favorites_store.get_users_that_are_currently_updating()

    resp = jsonify(users)
    resp.status_code = status.HTTP_200_OK

    return resp

# Notifies that a particular user has had their data requested
@application.route("/users/<user_id>/data-requested", methods = ['PUT'])
def put_user_data_requested(user_id=None):
    if user_id is None:
        return user_not_specified()

    favorites_store.user_data_requested(user_id)

    return "OK", status.HTTP_200_OK

# Notifies that a particular user has had their data successfully updated (i.e. for just themsolves)
@application.route("/users/<user_id>/data-updated", methods = ['PUT'])
def put_user_data_updated(user_id=None):
    if user_id is None:
        return user_not_specified()

    favorites_store.user_data_updated(user_id)

    return "OK", status.HTTP_200_OK

# Notifies that a particular user has had all of their data successfully updated (i.e. for all their neighbors)
@application.route("/users/<user_id>/all-data-updated", methods = ['PUT'])
def put_user_all_data_updated(user_id=None):
    if user_id is None:
        return user_not_specified()

    favorites_store.all_user_data_updated(user_id)

    return "OK", status.HTTP_200_OK

@application.errorhandler(status.HTTP_400_BAD_REQUEST)
def user_not_specified(error=None):
    return "User not specified", status.HTTP_400_BAD_REQUEST

@application.errorhandler(status.HTTP_400_BAD_REQUEST)
def parameter_not_specified(param_name, error=None):
    return f"Parameter {param_name} not specified", status.HTTP_400_BAD_REQUEST

if __name__ == '__main__':
    # Note that running Flask like this results in the output saying "lazy loading" and I'm not sure what that means.
    # If we run it the way specified in the documentation `FLASK_APP=./api-server.py flask run` then it doesn't say this.
    # But I wanted to be able to specify the port via a parameter rather than having to use an env var
    application.run(host=server_host, port=server_port)