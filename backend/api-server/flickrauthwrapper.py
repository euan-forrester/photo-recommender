from authlib.flask.client import OAuth
from authlib.client import OAuth1Session
from diskcache import Cache
from pymemcache.client.base import Client
from pymemcache import serde
import logging
import flickrapi
import uuid
import json
from flask import session

# authlib has some slightly different names for parameters, so we can't just pass a disc cache or memcached client directly to them

class DiscCacheWrapper():

    DISC_CACHE_PATH = "./tmp/flickr-auth-disc-cache"

    def __init__(self):
        self.disc_cache = Cache(directory=DiscCacheWrapper.DISC_CACHE_PATH)

    def get(self, key):
        # This can raise a diskcache.Timeout error if it fails to talk to its database
        return self.disc_cache.get(key=key, default=None, retry=False)

    def set(self, key, value, timeout=None):
        # This can raise a diskcache.Timeout error if it fails to talk to its database
        self.disc_cache.set(key=key, value=value, expire=timeout, retry=False)

    def delete(self, key):
        self.disc_cache.delete(key=key)

class MemcachedWrapper():

    MEMCACHED_CONNECT_TIMEOUT = 5   # 5 seconds
    MEMCACHED_TIMEOUT = 5           # 5 seconds

    def __init__(self, memcached_location):
        
        memcached_location_portions = memcached_location.split(":")
        if len(memcached_location_portions) != 2:
            raise ValueError(f"Found incorrectly formatted parameter memcached location: {memcached_location}") 

        memcached_host = memcached_location_portions[0]
        memcached_port = int(memcached_location_portions[1])

        self.memcached_client = Client(
            server=(memcached_host, memcached_port), 
            serializer=serde.python_memcache_serializer,
            deserializer=serde.python_memcache_deserializer,
            connect_timeout=MemcachedWrapper.MEMCACHED_CONNECT_TIMEOUT,
            timeout=MemcachedWrapper.MEMCACHED_TIMEOUT)

    def get(self, key):
        return self.memcached_client.get(key)

    def set(self, key, value, timeout=None):
        self.memcached_client.set(key, value, timeout) 

    def delete(self, key):
        self.memcached_client.delete(key)

class FlickrAuthWrapper():

    """
    Wraps the process of authenticating to Flickr and getting back an access token
    """

    ACCESS_LEVEL = 'write' # This is the amount of permissions that we need to be able to comment/favorite photos. Options are read/write/delete

    _req_token_tpl = '_{}_authlib_req_token_' # https://github.com/lepture/authlib/blob/master/authlib/flask/client/oauth.py#L11

    def __init__(self, application, cache_type, memcached_location, flickr_api_key, flickr_api_secret):
        
        # We can't use authlib's readymade OAuth class because vue-authenticate expects our auth function to behave differently.
        # authlib's class splits the auth into 2 endpoints, and returns a redirect, whereas vue-authenticate handles that from
        # the frontend side. Ultimately, our frontend is a SPA and just needs us to be an API, so returning a redirect to Flickr
        # here doesn't make any sense. So, we have to reimplement some of what the OAuth class does ourselves, using the building 
        # blocks provided by authlib: https://docs.authlib.org/en/latest/client/oauth1.html

        self.flickr_api_key = flickr_api_key
        self.flickr_api_secret = flickr_api_secret

        self.session_key = FlickrAuthWrapper._req_token_tpl.format("flickr")

        self.cache = None

        if cache_type == 'disc':
            self.cache = DiscCacheWrapper()
        elif cache_type == 'memcached':
            self.cache = MemcachedWrapper(memcached_location)

    def get_oauth_session(self, token=None, token_secret=None):
        session = OAuth1Session(self.flickr_api_key, self.flickr_api_secret, token=token, token_secret=token_secret)
        return session

    def fetch_request_token(self, session, redirect_uri):
        session.redirect_uri = redirect_uri
        return session.fetch_request_token('https://www.flickr.com/services/oauth/request_token')

    def fetch_access_token(self, session, verifier):
        token = session.fetch_access_token('https://www.flickr.com/services/oauth/access_token', verifier)
        return FlickrAuthWrapper._get_flickr_access_token(token)

    def get_request_token_from_cache(self):
        # Based on https://github.com/lepture/authlib/blob/master/authlib/flask/client/oauth.py#L132

        session_id = session.pop(self.session_key, None)
        if not session_id:
            return None

        token_pair = self.cache.get(session_id)

        return token_pair

    def put_request_token_in_cache(self, token, token_secret):

        # Based on https://github.com/lepture/authlib/blob/master/authlib/flask/client/oauth.py#L145

        token_pair = {
            'oauth_token': token,
            'oauth_token_secret': token_secret
        }

        session_id = uuid.uuid4().hex
        session[self.session_key] = session_id
        self.cache.set(session_id, token_pair, timeout=600)

    @staticmethod
    def _get_flickr_access_token(token):
        # Takes the token returned from the Flickr auth API and turns it into the internal object needed by the FlickrAPI package
        # https://github.com/sybrenstuvel/flickrapi/blob/master/flickrapi/auth.py#L96

        return flickrapi.auth.FlickrAccessToken(
            token=token['oauth_token'], 
            token_secret=token['oauth_token_secret'], 
            access_level=FlickrAuthWrapper.ACCESS_LEVEL,
            fullname=token['fullname'], 
            username=token['username'], 
            user_nsid=token['user_nsid'])

    @staticmethod
    def get_flickr_access_token_as_string(token):
        return json.dumps({
            'token': token.token,
            'token_secret': token.token_secret,
            'fullname': token.fullname,
            'username': token.username,
            'user_nsid': token.user_nsid
        })

    @staticmethod
    def get_flickr_access_token_no_secret_as_string(token):
        return json.dumps({
            'token': token.token,
            'fullname': token.fullname,
            'username': token.username,
            'user_nsid': token.user_nsid
        })

    @staticmethod
    def get_flickr_access_token_from_string(string):
        partial_token = json.loads(string)

        return flickrapi.auth.FlickrAccessToken(
            token=partial_token['token'], 
            token_secret=partial_token['token_secret'] if 'token_secret' in partial_token else "", 
            access_level=FlickrAuthWrapper.ACCESS_LEVEL,
            fullname=partial_token['fullname'], 
            username=partial_token['username'], 
            user_nsid=partial_token['user_nsid'])

    @staticmethod
    def fill_in_secret_in_access_token(token, secret):

        return flickrapi.auth.FlickrAccessToken(
            token=token.token, 
            token_secret=secret, 
            access_level=FlickrAuthWrapper.ACCESS_LEVEL,
            fullname=token.fullname, 
            username=token.username, 
            user_nsid=token.user_nsid)

    @staticmethod
    def get_user_id_from_token(token):
        return token.user_nsid