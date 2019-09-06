import flickrapi
import logging
import requests
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

        self.flickr                 = flickrapi.FlickrAPI(flickr_api_key, flickr_api_secret, format='parsed-json', cache=True)
        self.flickr.cache           = cache

        self.max_retries            = max_retries

        self.metrics_helper         = metrics_helper

    def lookup_user(self, user_url):
        
        lambda_to_call = lambda: self.flickr.urls.lookupUser(url=user_url)

        person_info = self._call_with_retries(lambda_to_call)

        logging.info(f"Just called lookup_user for url {user_url}")

        return person_info

    def get_person_info(self, user_id):
        
        lambda_to_call = lambda: self.flickr.people.getInfo(user_id=user_id)

        person_info = self._call_with_retries(lambda_to_call)

        logging.info(f"Just called get_person_info for user {user_id}")

        return person_info

    def get_favorites(self, user_id, max_favorites_per_call, max_favorites_to_get, max_calls_to_make):

        # We may want to put a limit on the number of pages that we request, because the Flickr API acts a bit weird.
        # We frequently get back less than the number of favorites we ask for, and so getting 1000 favorites in batches of 500
        # will generally require 3 calls rather than the expected 2. These calls are expensive, so we may want to limit them.

        got_all_favorites = False
        current_page = 1
        favorites = []

        while not got_all_favorites and (len(favorites) < max_favorites_to_get) and (current_page <= max_calls_to_make):
            favorites_subset = self._get_favorites_page(user_id, current_page, max_favorites_per_call)

            if len(favorites_subset['photos']['photo']) > 0: # We can't just check if the number we got back == the number we requested, because frequently we can get back < the number we requested but there's still more available. This is likely due to not having permission to be able to view all of the ones we requested
                favorites.extend(favorites_subset['photos']['photo'])
            else:
                got_all_favorites = True

            current_page += 1

        favorites_up_to_max = favorites[0:max_favorites_to_get]

        logging.info(f"Returning {len(favorites_up_to_max)} favorites which took {current_page - 1} calls. Max favorites to get: {max_favorites_to_get}. Max calls to make: {max_calls_to_make}")

        return favorites_up_to_max 

    def _get_favorites_page(self, user_id, page_number, max_favorites_per_call):

        # There's also flickr.favorites.getList(), which gets all the faves that our current API key can see. While it would be nice to get
        # more photos, some users might not be able to see the same things as this API key, so ultimately it'll result in broken links. 
        # Also some users might be upset at having their semi-private photos surfaced.
        lambda_to_call = lambda: self.flickr.favorites.getPublicList(user_id=user_id, extras='url_l,url_m', per_page=max_favorites_per_call, page=page_number)

        favorites = self._call_with_retries(lambda_to_call)

        logging.info(f"Just called get_favorites_page for page {page_number} with max_favorites_per_call {max_favorites_per_call} and returning {len(favorites['photos']['photo'])} faves")

        return favorites

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

                if e.code == 1:
                    logging.info("The requested object was not found. Throwing FlickrApiNotFoundException")
                    raise FlickrApiNotFoundException from e

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