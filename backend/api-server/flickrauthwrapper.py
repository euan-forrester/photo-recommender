from authlib.flask.client import OAuth
from diskcache import Cache
from pymemcache.client.base import Client
from pymemcache import serde
import logging

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
        self.memcached_client.get(key)

    def set(self, key, value, timeout=None):
        self.memcached_client.set(key, value, timeout) 

    def delete(self, key):
        self.memcached_client.delete(key)

class FlickrAuthWrapper():

    """
    Wraps the process of authenticating to Flickr and getting back an access token
    """

    def __init__(self, application, cache_type, memcached_location, flickr_api_key, flickr_api_secret):
        
        cache = None

        if cache_type == 'disc':
            cache = DiscCacheWrapper()
        elif cache_type == 'memcached':
            cache = MemcachedWrapper(memcached_location)

        oauth = OAuth(application, cache=cache)
        self.flickrauth = oauth.register(
                name='flickr', 
                client_id=flickr_api_key, 
                client_secret=flickr_api_secret, 
                request_token_url='https://www.flickr.com/services/oauth/request_token',
                request_token_params=None, # According to the authlib docs https://flask-oauthlib.readthedocs.io/en/latest/api.html, we can pass a dictionary here of extra parameters, and according to the Flickr docs https://www.flickr.com/services/api/auth.oauth.html we can pass a 'perms=' parameter to restrict permissions. But I can't seem to get it to work. Needs more testing.
                access_token_url='https://www.flickr.com/services/oauth/access_token',
                access_token_params=None,
                authorize_url='https://www.flickr.com/services/oauth/authorize',
                api_base_url='https://www.flickr.com/services/rest/',
                client_kwargs=None)

    def get_flickrauth(self):
        return self.flickrauth