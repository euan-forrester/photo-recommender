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
from favoritesstoreexception import FavoritesStoreUserNotFoundException
from favoritesstoreexception import FavoritesStoreDuplicateUserException
from metricshelper import MetricsHelper
from unhandledexceptionhelper import UnhandledExceptionHelper
from flickrapiwrapper import FlickrApiWrapper
from flickrapiwrapper import FlickrApiNotFoundException
from flickrauthwrapper import FlickrAuthWrapper
from flickrauthwrapper import AuthTokenIncorrectException
from flickrauthwrapper import NoAuthTokenProvidedException
from queuewriter import SQSQueueWriter
from pullerqueueitem import PullerQueueItem

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

metrics_namespace           = config_helper.get("metrics-namespace")
database_username           = config_helper.get("database-username")
database_password           = config_helper.get("database-password", is_secret=True)
database_host               = config_helper.get("database-host")
database_port               = config_helper.getInt("database-port")
database_name               = config_helper.get("database-name")
database_fetch_batch_size   = config_helper.getInt("database-fetch-batch-size")
database_connection_pool_size = config_helper.getInt("database-connection-pool-size")
database_user_data_encryption_key = config_helper.get("database-user-data-encryption-key", is_secret=True)
server_host                 = config_helper.get("server-host")
server_port                 = config_helper.getInt("server-port")
session_encryption_key      = config_helper.get("session-encryption-key", is_secret=True)
default_num_photo_recommendations = config_helper.getInt('default-num-photo-recommendations')
default_num_user_recommendations = config_helper.getInt('default-num-user-recommendations')
default_num_photos_from_group = config_helper.getInt('default-num-photos-from-group')

flickr_api_key              = config_helper.get("flickr-api-key")
flickr_api_secret           = config_helper.get("flickr-api-secret", is_secret=True)
flickr_api_retries          = config_helper.getInt("flickr-api-retries")
flickr_api_memcached_location   = config_helper.get("flickr-api-memcached-location")
flickr_api_memcached_ttl        = config_helper.getInt("flickr-api-memcached-ttl")

puller_queue_url            = config_helper.get("puller-queue-url")
puller_queue_batch_size     = config_helper.getInt("puller-queue-batchsize")

# We have a separate memcached instance for storing this info that isn't on a public subnet because it's storing potentially-sensitive user tokens (even though they're just the temporary tokens given during the auth process)
flickr_auth_cache_type      = config_helper.get("flickr-auth-cache-type")
flickr_auth_memcached_location = config_helper.get("flickr-auth-memcached-location")

#
# Metrics and unhandled exceptions
#

metrics_helper              = MetricsHelper(environment=config_helper.get_environment(), process_name="api-server", metrics_namespace=metrics_namespace)
unhandled_exception_helper  = UnhandledExceptionHelper.setup_unhandled_exception_handler(metrics_helper=metrics_helper)

#
# We're going to proxy requests to the Flickr API, because we have a secret that we need to maintain
#

flickrapi = FlickrApiWrapper(
    flickr_api_key=flickr_api_key, 
    flickr_api_secret=flickr_api_secret, 
    max_retries=flickr_api_retries, 
    memcached_location=flickr_api_memcached_location, 
    memcached_ttl=flickr_api_memcached_ttl, 
    metrics_helper=metrics_helper)

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
    connection_pool_size=database_connection_pool_size,
    user_data_encryption_key=database_user_data_encryption_key)

def cleanup_data_store():
    favorites_store.shutdown()

atexit.register(cleanup_data_store)

#
# And our queue. We write to this when a user favorites a recommendation, so that we can update our recommendations by pulling all of the favorite's favorites
#

flickr_puller_queue = SQSQueueWriter(puller_queue_url, puller_queue_batch_size, metrics_helper)

#
# Run our API server
#
# Note that the Flask built-in server is not sufficient for production. In production we run under gunicorn instead, and
# we run behind an AWS Application Load Balancer. See: 
#   https://medium.com/@kmmanoj/deploying-a-scalable-flask-app-using-gunicorn-and-nginx-in-docker-part-1-3344f13c9649
#

application = Flask(__name__)
application.secret_key = session_encryption_key

flickr_auth_wrapper = FlickrAuthWrapper(
    application=application, 
    cache_type=flickr_auth_cache_type,
    memcached_location=flickr_auth_memcached_location,
    flickr_api_key=flickr_api_key, 
    flickr_api_secret=flickr_api_secret)

# Health check for our load balancer
@application.route("/healthcheck", methods = ['GET'])
def health_check():
    return "OK", status.HTTP_200_OK

# vue-authenticate has a bit of a seemingly-nonstandard way of
# interacting with our API: it does it all with one method that
# is called twice and passed different parameters.
# This is modelled on the example here: https://github.com/dgrubelic/vue-authenticate/blob/739c7fc894089c67b7a2badeb7a5fb97720ca0cd/example/server.js#L275 
@application.route('/api/flickr/auth', methods = ['POST'])
def flickr_auth():
    
    request_data = request.get_json()

    if not ('oauth_token' in request_data):

        redirect_uri    = request_data['redirectUri']
        oauth_session   = flickr_auth_wrapper.get_oauth_session()
        request_token   = flickr_auth_wrapper.fetch_request_token(oauth_session, redirect_uri)
        
        flickr_auth_wrapper.put_request_token_in_cache(request_token['oauth_token'], request_token['oauth_token_secret'])

        return_value = {
            'oauth_token': request_token['oauth_token']
            # The example shows passing back the secret as well, but it's ignored
            # by the vue-authenticate library
        }

        return jsonify(return_value)

    else:

        token_pair = flickr_auth_wrapper.get_request_token_from_cache()

        if token_pair is None:
            logging.error("Could not find request token in cache")
            raise RuntimeError("Could not find request token in cache")

        if token_pair['oauth_token'] != request_data['oauth_token']:
            logging.error(f"Was passed different oauth_token than found in cache. Was passed {request_data['oauth_token']}, but found {token_pair['oauth_token']} in cache")
            raise RuntimeError("Was passed different oauth_token than found in cache")

        oauth_token         = token_pair['oauth_token']
        oauth_token_secret  = token_pair['oauth_token_secret']
        verifier            = request_data['oauth_verifier']
        oauth_session       = flickr_auth_wrapper.get_oauth_session(token=oauth_token, token_secret=oauth_token_secret)
        access_token        = flickr_auth_wrapper.fetch_access_token(oauth_session, verifier)

        user_id             = flickr_auth_wrapper.get_user_id_from_token(access_token)

        logging.info(f"Attempting to create new user {user_id}")

        try:
            favorites_store.create_user(user_id)
        except FavoritesStoreDuplicateUserException as e:
            logging.info(f"User {user_id} already exists. Continuing")

        favorites_store.save_user_auth_token(user_id, flickr_auth_wrapper.get_flickr_access_token_as_string(access_token))

        return_value = {
            'access_token': flickr_auth_wrapper.get_flickr_access_token_as_string_no_secret(access_token) # Return a version of the token that doesn't include the secret. We'll fill it in from the database on subsequent calls
            # The example shows passing back the secret as well, but it's ignored
            # by the vue-authenticate library
        }

        return jsonify(return_value)

@application.route("/api/flickr/auth/logout", methods = ["POST"])
def flickr_logout():

    try:
        full_token  = _get_and_test_full_user_oauth_token(request)
        user_id     = flickr_auth_wrapper.get_user_id_from_token(full_token)

        logging.info(f"Requested logout for user {user_id}")

        favorites_store.delete_user_auth_token(user_id)

    except NoAuthTokenProvidedException as e:
        logging.info("No auth token provided while attempting to log out. Assuming user is already logged out, and ignoring.")

    return "OK", status.HTTP_200_OK

@application.route("/api/flickr/photos/add-comment", methods = ['POST'])
def flickr_add_comment():

    request_data = request.get_json()

    photo_id        = request.args.get('photo-id')
    comment_text    = request_data['comment-text']

    if not photo_id:
        return parameter_not_specified("photo-id")

    if not comment_text:
        return parameter_not_specified("comment-text")

    full_token = _get_and_test_full_user_oauth_token(request)

    resp = jsonify(flickrapi.add_comment(photo_id, comment_text, full_token))
    resp.status_code = status.HTTP_200_OK

    return resp  

@application.route("/api/flickr/favorites/add", methods = ['POST'])
def flickr_add_favorite():

    request_data = request.get_json()

    image_id    = request_data['image-id']
    image_owner = request_data['image-owner']
    image_url   = request_data['image-url']

    if not image_id:
        return parameter_not_specified("image-id")

    if not image_owner:
        return parameter_not_specified("image-owner")

    if not image_url:
        return parameter_not_specified("image-url")

    full_token = _get_and_test_full_user_oauth_token(request)

    favorited_by = flickr_auth_wrapper.get_user_id_from_token(full_token)

    # First, tell Flickr that it was favorited because if this fails we don't want our database
    # to be out of sync with theirs

    logging.info("Beginning adding new favorite. About to tell Flickr that a new favorite has been added")

    flickrapi.add_favorite(image_id, full_token)

    # Then, add this favorite to our database so that we know about it. No need to wait
    # until the next time this user's data is scheduled to be pulled

    logging.info("About to write to our database that a new favorite has been added")

    favorites_store.add_favorite(image_id, image_owner, image_url, favorited_by)

    # Request that all of the image owner's favorites be pulled (if they haven't been already).
    # Because this is just one pull request, it'll be fulfilled quite quickly and so will offer
    # near-realtime new results to the user if they refresh their recommendations

    logging.info(f"About to make a puller request to {puller_queue_url} to get the favorites of the favorited image {image_owner}")

    flickr_pull_request = PullerQueueItem(user_id=image_owner, initial_requesting_user_id=favorited_by, request_favorites=True, request_contacts=False, request_neighbor_list=False)

    flickr_puller_queue.send_messages(objects=[flickr_pull_request], to_string=lambda queue_item : queue_item.to_json())

    # Update our database to say that there's an outstanding puller request for this user

    logging.info(f"About to update our database that there's an outstanding puller request for the user who made the favorite {favorited_by}")

    favorites_store.more_puller_requests(favorited_by, 1)

    logging.info("Finished adding new favorite")

    return "OK", status.HTTP_200_OK

@application.route("/api/flickr/test/login", methods = ['POST'])
def flickr_get_logged_in_user():
    
    full_token = _get_and_test_full_user_oauth_token(request)

    resp = jsonify(flickrapi.login_test(full_token))
    resp.status_code = status.HTTP_200_OK

    return resp  

def _get_and_test_full_user_oauth_token(request):

    request_data = request.get_json()

    partial_token_from_caller_string = request_data['oauth-token']

    if not partial_token_from_caller_string:
        raise NoAuthTokenProvidedException()

    partial_token_from_caller = flickr_auth_wrapper.get_flickr_access_token_from_string(partial_token_from_caller_string)

    user_id = flickr_auth_wrapper.get_user_id_from_token(partial_token_from_caller)

    full_token = flickr_auth_wrapper.get_flickr_access_token_from_string(favorites_store.get_user_auth_token(user_id))

    if not flickr_auth_wrapper.tokens_are_equal(partial_token_from_caller, full_token):
        raise AuthTokenIncorrectException()

    return full_token

# Create a new user
@application.route("/api/users/<user_id>", methods = ['POST'])
def create_user(user_id=None):
    if user_id is None:
        return user_not_specified()

    # We could add a check here to see if it's a legitimate user in Flickr, but we'd have to do a lot more
    # engineering. We can't just do a simple check here because if it fails for transient reasons then
    # we'll have lost this call. So we'd have to have a queue and retries, which I don't think is worth it for this

    favorites_store.create_user(user_id)

    user_info = favorites_store.get_user_info(user_id)

    resp = jsonify(user_info)
    resp.status_code = status.HTTP_200_OK

    return resp

# Delete a user
@application.route("/api/users/<user_id>", methods = ['DELETE'])
def delete_user(user_id=None):
    if user_id is None:
        return user_not_specified()

    favorites_store.delete_user(user_id)

    return "OK", status.HTTP_200_OK

# Gets some information about this user
@application.route("/api/users/<user_id>", methods = ['GET'])
def get_user_info(user_id=None):
    if user_id is None:
        return user_not_specified()

    user_info = favorites_store.get_user_info(user_id)

    resp = jsonify(user_info)
    resp.status_code = status.HTTP_200_OK

    do_not_cache_response(resp)

    return resp

# Gets our recommendations for a specific user
@application.route("/api/users/<user_id>/recommendations", methods = ['GET'])
def get_recommendations(user_id=None):
    if user_id is None:
        return user_not_specified()

    num_photos  = int(request.args.get('num-photos',    default_num_photo_recommendations))
    num_users   = int(request.args.get('num-users',     default_num_user_recommendations))

    photo_recommendations   = favorites_store.get_photo_recommendations(user_id, num_photos)
    user_recommendations    = favorites_store.get_user_recommendations(user_id, num_users)

    output = {
        'photos':   [e.get_output() for e in photo_recommendations], # Can't directly encode these classes, but we can return an easy-to-encode dict for each element
        'users':    [e.get_output() for e in user_recommendations]
    }

    resp = jsonify(output) 
    resp.status_code = status.HTTP_200_OK

    # When we navigate away from our recommendations page, then hit the back button, the browser
    # uses a cached version of our response rather than asking again. This is a problem if
    # the user has dismissed some photos or users: the cached response won't reflect those
    # updates and it'll show the dismissed recommendations. So, we ask the browser not to cache this response. 
    #
    # This means that empty spaces that used to hold user recommendations will be filled in
    # by new recommendations that exclude the dismissed ones. But at least it doesn't
    # show the dismissed recommendations.
    do_not_cache_response(resp)

    return resp

# Gets a list of registered users who need to have their data refreshed
@application.route("/api/users/need-update", methods = ['GET'])
def get_users_that_need_update():

    num_seconds_between_updates = request.args.get('num-seconds-between-updates')

    if not num_seconds_between_updates:
        return parameter_not_specified("num-seconds-between-updates")

    users = favorites_store.get_users_that_need_updated(int(num_seconds_between_updates))

    resp = jsonify(users)
    resp.status_code = status.HTTP_200_OK

    return resp

# Gets a list of registered users who are currently in the process of having their data refreshed
@application.route("/api/users/currently-updating", methods = ['GET'])
def get_users_that_are_currently_updating():

    users = favorites_store.get_users_that_are_currently_updating()

    resp = jsonify(users)
    resp.status_code = status.HTTP_200_OK

    return resp

# Notifies that a particular user has had their data requested
@application.route("/api/users/<user_id>/data-requested", methods = ['PUT'])
def put_user_data_requested(user_id=None):
    if user_id is None:
        return user_not_specified()

    num_puller_requests = request.args.get('num-puller-requests')

    if not num_puller_requests:
        return parameter_not_specified("num-puller-requests")

    favorites_store.user_data_requested(user_id, num_puller_requests)

    return "OK", status.HTTP_200_OK

# Notifies that there have been more puller requests made for a particular user
@application.route("/api/users/<user_id>/more-puller-requests", methods = ['PUT'])
def put_user_more_puller_requests(user_id=None):
    if user_id is None:
        return user_not_specified()

    num_puller_requests = request.args.get('num-puller-requests')

    if not num_puller_requests:
        return parameter_not_specified("num-puller-requests")

    favorites_store.more_puller_requests(user_id, num_puller_requests)

    return "OK", status.HTTP_200_OK

# Notifies that there have been some puller responses for a particular user
@application.route("/api/users/<user_id>/received-puller-responses", methods = ['PUT'])
def put_user_received_puller_responses(user_id=None):
    if user_id is None:
        return user_not_specified()

    num_puller_responses = request.args.get('num-puller-responses')

    if not num_puller_responses:
        return parameter_not_specified("num-puller-responses")

    finished_processing = favorites_store.received_puller_responses(user_id, num_puller_responses)

    response_object = {
        'finished_processing': finished_processing
    }

    resp = jsonify(response_object)
    resp.status_code = status.HTTP_200_OK

    return resp

# Notifies that there have been some ingester responses for a particular user
@application.route("/api/users/<user_id>/received-ingester-responses", methods = ['PUT'])
def put_user_received_ingester_responses(user_id=None):
    if user_id is None:
        return user_not_specified()

    num_ingester_responses = request.args.get('num-ingester-responses')

    if not num_ingester_responses:
        return parameter_not_specified("num-ingester-responses")

    finished_processing = favorites_store.received_ingester_responses(user_id, num_ingester_responses)

    response_object = {
        'finished_processing': finished_processing
    }

    resp = jsonify(response_object)
    resp.status_code = status.HTTP_200_OK

    return resp

# Gets how long it took for a particular user has had all of their data successfully updated
@application.route("/api/users/<user_id>/get-time-to-update-all-data", methods = ['GET'])
def get_time_to_update_all_data(user_id=None):
    if user_id is None:
        return user_not_specified()

    response_object = {
        'time_in_seconds': favorites_store.get_time_to_update_all_data(user_id)
    }

    resp = jsonify(response_object)
    resp.status_code = status.HTTP_200_OK

    return resp

# Notifies that a user no longer wants to see a particular photo recommendation
@application.route("/api/users/<user_id>/dismiss-photo-recommendation", methods = ['PUT'])
def put_user_dismiss_photo_recommendation(user_id=None):
    if user_id is None:
        return user_not_specified()

    recommendation_image_id = request.args.get('image-id')

    if not recommendation_image_id:
        return parameter_not_specified("image-id")

    favorites_store.dismiss_photo_recommendation(user_id, recommendation_image_id)

    return "OK", status.HTTP_200_OK

# Notifies that a user no longer wants to see a particular user recommendation
@application.route("/api/users/<user_id>/dismiss-user-recommendation", methods = ['PUT'])
def put_user_dismiss_user_recommendation(user_id=None):
    if user_id is None:
        return user_not_specified()

    recommendation_user_id = request.args.get('user-id')

    if not recommendation_user_id:
        return parameter_not_specified("user-id")

    favorites_store.dismiss_user_recommendation(user_id, recommendation_user_id)

    return "OK", status.HTTP_200_OK

@application.route("/api/locks/request", methods = ['PUT'])
def request_lock():

    process_id              = request.args.get("process-id")
    task_id                 = request.args.get("task-id")
    lock_duration_seconds   = request.args.get("lock-duration-seconds")

    if not process_id:
        return parameter_not_specified("process-id")

    if not task_id:
        return parameter_not_specified("task-id")

    if not lock_duration_seconds:
        return parameter_not_specified("lock-duration-seconds")

    response_object = {
        'process_id':       process_id,
        'task_id':          task_id,
        'lock-acquired':    favorites_store.request_lock(process_id, task_id, lock_duration_seconds)
    }

    resp = jsonify(response_object)
    resp.status_code = status.HTTP_200_OK

    return resp


@application.route("/api/flickr/urls/lookup-user", methods = ['GET'])
def get_flickr_lookup_user():

    url = request.args.get("url")

    if not url:
        return parameter_not_specified("url")

    resp = jsonify(flickrapi.lookup_user(user_url=url))
    resp.status_code = status.HTTP_200_OK

    return resp

@application.route("/api/flickr/people/get-info", methods = ['GET'])
def get_flickr_get_person_info():

    user_id = request.args.get("user-id")

    if not user_id:
        return parameter_not_specified("user-id")

    resp = jsonify(flickrapi.get_person_info(user_id=user_id))
    resp.status_code = status.HTTP_200_OK

    return resp

@application.route("/api/flickr/contacts/get-list", methods = ['GET'])
def get_flickr_get_contacts():

    user_id = request.args.get("user-id")

    if not user_id:
        return parameter_not_specified("user-id")

    resp = jsonify(flickrapi.get_contacts(user_id=user_id, max_contacts_per_call=1000))
    resp.status_code = status.HTTP_200_OK

    return resp

@application.route("/api/flickr/groups/get-info", methods = ['GET'])
def get_flickr_get_group_info():

    group_id = request.args.get("group-id")

    if not group_id:
        return parameter_not_specified("group-id")

    resp = jsonify(flickrapi.get_group_info(group_id=group_id))
    resp.status_code = status.HTTP_200_OK

    return resp

@application.route("/api/flickr/groups/pools/get-photos", methods = ['GET'])
def get_flickr_get_group_photos():

    group_id    = request.args.get("group-id")
    num_photos  = int(request.args.get('num-photos', default_num_photos_from_group))

    if not group_id:
        return parameter_not_specified("group-id")

    resp = jsonify(flickrapi.get_group_photos(group_id=group_id, num_photos=num_photos))
    resp.status_code = status.HTTP_200_OK

    return resp

@application.route("/favicon.ico", methods = ['GET'])
def get_favicon():
    # Browsers like to call this, and without defining this route we see 404 errors in our logs
    return "OK", status.HTTP_200_OK

@application.errorhandler(status.HTTP_400_BAD_REQUEST)
def user_not_specified(error=None):
    return "User not specified", status.HTTP_400_BAD_REQUEST

@application.errorhandler(status.HTTP_400_BAD_REQUEST)
def parameter_not_specified(param_name, error=None):
    return f"Parameter {param_name} not specified", status.HTTP_400_BAD_REQUEST

@application.errorhandler(NoAuthTokenProvidedException)
def no_auth_token_provided(e):
    return "No OAuth token found in request", status.HTTP_400_BAD_REQUEST

@application.errorhandler(AuthTokenIncorrectException)
def auth_token_incorrect(e):
    return "OAuth token provided did not match our records for this user", status.HTTP_400_BAD_REQUEST

@application.errorhandler(FavoritesStoreException)
def encountered_favorites_store_exception(e):
    metrics_helper.increment_count("FavoritesStoreException")
    logging.exception("Encountered FavoritesStoreException") # Logs a stack trace
    return "Internal server error", status.HTTP_500_INTERNAL_SERVER_ERROR, do_not_cache()

@application.errorhandler(FavoritesStoreUserNotFoundException)
def encountered_user_not_found_exception(e):
    return "Requested user not found", status.HTTP_404_NOT_FOUND, do_not_cache()

@application.errorhandler(FavoritesStoreDuplicateUserException)
def encountered_duplicate_not_exception(e):
    return "Requested user already exists", status.HTTP_409_CONFLICT, do_not_cache()

@application.errorhandler(FlickrApiNotFoundException)
def encountered_flickr_not_found_exception(e):
    return "Requested object not found", status.HTTP_404_NOT_FOUND, do_not_cache()

@application.errorhandler(Exception)
def encountered_exception(e):
    metrics_helper.increment_count("Exception")
    logging.exception("Excountered Exception") # Logs a stack trace
    return "Internal server error", status.HTTP_500_INTERNAL_SERVER_ERROR

def do_not_cache_response(resp):
    # Note that there are settings in the response that provide a cleaner way to do this: https://stackoverflow.com/questions/23112316/using-flask-how-do-i-modify-the-cache-control-header-for-all-output/23115561#23115561
    resp.headers["Cache-Control"] = "no-cache, max-age=0, must-revalidate, no-store" # https://blog.55minutes.com/2011/10/how-to-defeat-the-browser-back-button-cache/

def do_not_cache():
    return {
        "Cache-Control": "no-cache, max-age=0, must-revalidate, no-store"
    }

if __name__ == '__main__':
    # Note that running Flask like this results in the output saying "lazy loading" and I'm not sure what that means.
    # If we run it the way specified in the documentation `FLASK_APP=./api-server.py flask run` then it doesn't say this.
    # But I wanted to be able to specify the port via a parameter rather than having to use an env var
    application.run(host=server_host, port=server_port)