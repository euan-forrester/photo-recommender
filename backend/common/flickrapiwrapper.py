import flickrapi
import logging
import requests
import json
from django.core.cache import cache
from django.conf import settings

class FlickrApiException(Exception):
    pass

class FlickrApiNotFoundException(Exception):
    pass

class FlickrApiWrapper:

    """
    Wraps around the flickrapi package: adds in retries to calls that fail, and external cacheing via memcached
    """

    def __init__(self, flickr_api_key, flickr_api_secret, memcached_location, memcached_ttl, max_retries, metrics_helper):

        settings.configure(CACHES = {
            'default': {
                'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
                'LOCATION': memcached_location,
                'KEY_FUNCTION': FlickrApiWrapper._make_memcached_key,
                'TIMEOUT': memcached_ttl,
            }
        })

        self.flickr_api_key      = flickr_api_key
        self.flickr_api_secret   = flickr_api_secret
        self.cache               = cache

        self.unauth_flickr       = flickrapi.FlickrAPI(self.flickr_api_key, self.flickr_api_secret, format='parsed-json', cache=True) # Not authenticated; used to make calls that don't require auth
        self.unauth_flickr.cache = self.cache

        self.max_retries         = max_retries

        self.metrics_helper      = metrics_helper

    def login_test(self, user_authentication_token):

        auth_flickr = self._get_auth_flickr(user_authentication_token)

        lambda_to_call = lambda: auth_flickr.test.login()

        person_info = self._call_with_retries(lambda_to_call)

        return person_info

    def add_comment(self, photo_id, comment_text, user_authentication_token):

        try:

            auth_flickr = self._get_auth_flickr(user_authentication_token)

            lambda_to_call = lambda: auth_flickr.photos.comments.addComment(photo_id=photo_id, comment_text=comment_text)

            comment_id = self._call_with_retries(lambda_to_call)

            return comment_id

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested photo was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

    def add_favorite(self, photo_id, user_authentication_token):

        try:

            auth_flickr = self._get_auth_flickr(user_authentication_token)

            lambda_to_call = lambda: auth_flickr.favorites.add(photo_id=photo_id)

            resp = self._call_with_retries(lambda_to_call)

            return resp

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested photo was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

            elif e.code == 3:
                logging.info("The requested photo is already a favorite of this user. Continuing.")
                # This Flickr API function doesn't return anything in its response, and we ignore the response when calling this function. So it's okay to not return anything here
                return {}

    def lookup_user(self, user_url):
        
        try:

            lambda_to_call = lambda: self.unauth_flickr.urls.lookupUser(url=user_url)

            person_info = self._call_with_retries(lambda_to_call)

            logging.info(f"Just called lookup_user for url {user_url}")

            return person_info

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested URL was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

    def get_person_info(self, user_id):
        
        try:

            lambda_to_call = lambda: self.unauth_flickr.people.getInfo(user_id=user_id)

            person_info = self._call_with_retries(lambda_to_call)

            logging.info(f"Just called get_person_info for user {user_id}")

            return person_info

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested user ID was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

    def get_group_info(self, group_id):
    
        try:

            lambda_to_call = lambda: self.unauth_flickr.groups.getInfo(group_id=group_id)

            group_info = self._call_with_retries(lambda_to_call)

            logging.info(f"Just called get_group_info for group {group_id}")

            return group_info

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested group ID was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

    def get_group_photos(self, group_id, num_photos):
        
        try:

            lambda_to_call = lambda: self.unauth_flickr.groups.pools.getPhotos(group_id=group_id, extras='url_l,url_m', per_page=num_photos, page=1) # Max per page is 500, and we'll always want way less than that

            group_photos = self._call_with_retries(lambda_to_call)

            logging.info(f"Just called get_group_photos for group {group_id}, with num photos {num_photos}")

            return group_photos

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested group ID was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

    def get_favorites(self, user_id, max_favorites_per_call, max_favorites_to_get, max_calls_to_make):

        # We may want to put a limit on the number of pages that we request, because the Flickr API acts a bit weird.
        # We frequently get back less than the number of favorites we ask for, and so getting 1000 favorites in batches of 500
        # will generally require 3 calls rather than the expected 2. These calls are expensive, so we may want to limit them.

        got_all_favorites = False
        current_page = 1
        favorites = []

        while not got_all_favorites and (len(favorites) < max_favorites_to_get) and (current_page <= max_calls_to_make):
            favorites_subset = self._get_favorites_page(user_id, current_page, max_favorites_per_call)

            favorites_subset_found = []

            if 'photo' in favorites_subset['photos']:
                favorites_subset_found = favorites_subset['photos']['photo']

            if len(favorites_subset_found) > 0: # We can't just check if the number we got back == the number we requested, because frequently we can get back < the number we requested but there's still more available. This is likely due to not having permission to be able to view all of the ones we requested
                favorites.extend(favorites_subset_found)
            else:
                got_all_favorites = True

            current_page += 1

        favorites_up_to_max = favorites[0:max_favorites_to_get]

        logging.info(f"Returning {len(favorites_up_to_max)} favorites which took {current_page - 1} calls. Max favorites to get: {max_favorites_to_get}. Max calls to make: {max_calls_to_make}")

        return favorites_up_to_max 

    def _get_favorites_page(self, user_id, page_number, max_favorites_per_call):

        try:

            # There's also unauth_flickr.favorites.getList(), which gets all the faves that our current API key can see. While it would be nice to get
            # more photos, some users might not be able to see the same things as this API key, so ultimately it'll result in broken links. 
            # Also some users might be upset at having their semi-private photos surfaced.
            lambda_to_call = lambda: self.unauth_flickr.favorites.getPublicList(user_id=user_id, extras='url_l,url_m', per_page=max_favorites_per_call, page=page_number)

            favorites = self._call_with_retries(lambda_to_call)

            logging.info(f"Just called get_favorites_page() for page {page_number} with max_favorites_per_call {max_favorites_per_call} and returning {len(favorites['photos']['photo'])} faves")

            return favorites

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested user ID was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

    def get_contacts(self, user_id, max_contacts_per_call):

        # Unlike get_favorites() above, we don't want to put any limits on this data because we need to look through all of our contacts
        # to see whether a user we're recommending is someone that is already being followed by the user in question

        got_all_contacts = False
        current_page = 1
        contacts = []

        while not got_all_contacts:
            contacts_subset = self._get_contacts_page(user_id, current_page, max_contacts_per_call)

            if len(contacts_subset) > 0: # We can't just check if the number we got back == the number we requested, because frequently we can get back < the number we requested but there's still more available. This is likely due to not having permission to be able to view all of the ones we requested
                contacts.extend(contacts_subset)
            else:
                got_all_contacts = True

            current_page += 1

        logging.info(f"Returning {len(contacts)} contacts which took {current_page - 1} calls.")

        # There's some extraneous information included from the Flickr API, like their username and whether we're ignoring them, but we don't need that

        return [e["nsid"] for e in contacts] 

    def _get_contacts_page(self, user_id, page_number, max_contacts_per_call):

        try:

            # There's also unauth_flickr.contacts.getList(), but it requires authentication. 
            # It would be nice to be more accurate by getting all of our contacts, but that would require doing this on the frontend side rather than
            # in the database, which seems like a world of hurt. We'd have to get all of the user's contacts, then keep getting more an more recommendations
            # of users until we'd filled the required number. Seems complicated and slow vs just doing it all in a single SQL statement.
            lambda_to_call = lambda: self.unauth_flickr.contacts.getPublicList(user_id=user_id, per_page=max_contacts_per_call, page=page_number)

            response = self._call_with_retries(lambda_to_call)

            contacts = []

            if 'contact' in response['contacts']:
                contacts = response['contacts']['contact']

            logging.info(f"Just called get_contacts_page() for page {page_number} with max_contacts_per_call {max_contacts_per_call} and returning {len(contacts)} contacts")

            return contacts

        except flickrapi.exceptions.FlickrError as e:
            if e.code == 1:
                logging.info("The requested user ID was not found. Throwing FlickrApiNotFoundException")
                raise FlickrApiNotFoundException from e

    def _get_auth_flickr(self, user_authentication_token):
        
        # Gets an instance of FlickrAPI that is authenticated to a particular user

        auth_flickr         = flickrapi.FlickrAPI(self.flickr_api_key, self.flickr_api_secret, token=user_authentication_token, store_token=False, format='parsed-json', cache=True)
        auth_flickr.cache   = self.cache

        return auth_flickr

    @staticmethod
    def _make_memcached_key(key, key_prefix, version):
        
        # Similar to the default key function, except that we translate the key first. The FlickrAPI package
        # uses objects as keys, then calls repr() on it to translate it into a string. This means the string will have 
        # spaces in the name, but memcached won't accept spaces in the key names, so we have to replace those

        translated_key = repr(key).replace(' ', '$')

        return '%s:%s:%s' % (key_prefix, version, translated_key)

    def _call_with_retries(self, lambda_to_call):

        num_retries = 0
        result = None
        success = False
        error = None

        while (num_retries < self.max_retries) and not success:
            try:
                result = lambda_to_call()
                success = True

            except flickrapi.exceptions.FlickrError as e:

                if e.code is not None: # For some calls that are returned status 500, the error code is not set

                    # For known error numbers, the caller needs to deal with the exception because
                    # the same number can mean something different depending on what the original call was.
                    # 
                    # For example, error code 1 usually means "<user|grouop|photo|etc> ID not found", except
                    # for flickr.contacts.getList() where it means "Invalid sort parameter".
                    # Note that we instead call flickr.contacts.getPublicList() where it *does* in fact mean
                    # "user ID not found", but it seems like a frustrating gotcha to assume it always means
                    # that for every call. Better to force the programmer to check each time a new call is added.
                    if e.code <= 116:
                        raise e

                # You get random 502s when making lots of calls to this API, which apparently indicate rate limiting: 
                # https://www.flickr.com/groups/51035612836@N01/discuss/72157646430151464/ 
                # Sleeping between calls didn't seem to always solve it, but retrying does
                # There doesn't seem to be a way to determine that this happened from the exception object other than to test
                # the string against "do_request: Status code 502 received"
                logging.info(f"Got FlickrError {e}")
                error = e

            except requests.exceptions.ConnectionError as e:
                logging.debug(f"Got ConnectionError {e}")
                # Sometimes we see a random "Remote end closed connection without response" error
                error = e

            num_retries += 1

        if not success:
            self.metrics_helper.increment_count("FlickrApiException")
            raise FlickrApiException(f"Failed contacting Flickr API after {self.max_retries} retries") from error

        self.metrics_helper.increment_count("flickr_api_retries", num_retries - 1)

        return result 