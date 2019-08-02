import configparser
import boto3
from botocore.exceptions import ClientError
import logging
import os
from pymemcache.client.base import Client
from pymemcache import serde

class ConfigHelper:
    
    @staticmethod
    def get_config_helper(default_env_name, aws_parameter_prefix):
        if not "ENVIRONMENT" in os.environ:
            logging.info("Did not find ENVIRONMENT environment variable, running in development mode and loading config from config files.")

            return ConfigHelperFile(environment=default_env_name, filename_list=["config/config.ini", "config/secrets.ini"])

        else:
            ENVIRONMENT = os.environ.get('ENVIRONMENT')

            logging.info(f"Found ENVIRONMENT environment variable containing '{ENVIRONMENT}': assuming we're running in AWS and getting our parameters from the AWS Parameter Store")

            return ConfigHelperParameterStore(environment=ENVIRONMENT, key_prefix=aws_parameter_prefix)

    @staticmethod
    def _log(param, value, is_secret, is_cached=False):
        logging.info(f"Got parameter {param} {ConfigHelper._get_is_cached_log_string(is_cached)} with value {ConfigHelper._get_value_log_string(value, is_secret)}")

    @staticmethod
    def _get_is_cached_log_string(is_cached):
        if is_cached:
            return "from the cache"
        else:
            return "directly from the store" 

    @staticmethod
    def _get_value_log_string(value, is_secret):
        if is_secret:
            return "<secret>"
        else:
            return f"{value}" 

class ConfigHelperFile(ConfigHelper):
    
    '''
    Uses the ConfigParser library to read config items from a set of local files
    '''

    def __init__(self, environment, filename_list):
        self.environment    = environment
        self.config         = configparser.ConfigParser()

        for filename in filename_list:
            logging.info(f"Reading in config file '{filename}'")
            self.config.read(filename)

    def get_environment(self):
        return self.environment

    def get(self, key, is_secret=False):
        try:
            value = self.config.get(self.environment, key)
            ConfigHelper._log(key, value, is_secret)
            return value

        except configparser.NoOptionError as e:
            raise ParameterNotFoundException(message=f'Could not get parameter {key}') from e

    # This will throw a ValueError if the parameter doesn't contain an int
    def getInt(self, key, is_secret=False):
        try:
            value = self.config.getint(self.environment, key)
            ConfigHelper._log(key, value, is_secret)
            return value

        except configparser.NoOptionError as e:
            raise ParameterNotFoundException(message=f'Could not get parameter {key}') from e

class ConfigHelperParameterStore(ConfigHelper):

    '''
    Reads config items from the AWS Parameter Store
    '''

    MEMCACHED_TTL = 300             # 5 minutes
    MEMCACHED_CONNECT_TIMEOUT = 5   # 5 seconds
    MEMCACHED_TIMEOUT = 5           # 5 seconds

    def __init__(self, environment, key_prefix):
        self.environment    = environment
        self.key_prefix     = key_prefix
        self.ssm            = boto3.client('ssm') # Region is read from the AWS_DEFAULT_REGION env var
        self.memcached_location = self._get_from_parameter_store(self._get_full_path("parameter-memcached-location"))
        self.memcached_client = None

        if self.memcached_location is None:
            logging.info(f"Could not find parameter memcached location in parameter store at {self._get_full_path('parameter-memcached-location')}")

        else:
            logging.info(f"Found parameter memcached location {self.memcached_location}")

            memcached_location_portions = self.memcached_location.split(":")
            if len(memcached_location_portions) != 2:
                raise ValueError(f"Found incorrectly formatted parameter memcached location: {self.memcached_location}") 

            memcached_host = memcached_location_portions[0]
            memcached_port = int(memcached_location_portions[1])
            
            self.memcached_client = Client(
                server=(memcached_host, memcached_port), 
                serializer=serde.python_memcache_serializer,
                deserializer=serde.python_memcache_deserializer,
                connect_timeout=ConfigHelperParameterStore.MEMCACHED_CONNECT_TIMEOUT,
                timeout=ConfigHelperParameterStore.MEMCACHED_TIMEOUT)

    def get_environment(self):
        return self.environment

    def get(self, key, is_secret=False):

        # With lots of container instances running, each one is constantly getting values from 
        # the parameter store and we can start to see ourselves getting throttled. So,
        # put all of our values into memcached instead

        full_path = self._get_full_path(key)

        if is_secret or self.memcached_client is None:
            # Don't cache secret parameters because they'll be stored unencrypted in the cache
            value = self._get_from_parameter_store(full_path, is_secret)
            ConfigHelper._log(full_path, value, is_secret, is_cached=False)
            return value

        value_from_cache = self._get_from_cache(full_path)

        if value_from_cache is not None:
            ConfigHelper._log(full_path, value_from_cache, is_secret, is_cached=True)
            return value_from_cache

        value = self._get_from_parameter_store(full_path, is_secret)

        ConfigHelper._log(full_path, value, is_secret, is_cached=False)

        self._write_to_cache(full_path, value)

        return value

    def _get_from_cache(self, full_path):

        return self.memcached_client.get(full_path)

    def _write_to_cache(self, full_path, value):

        self.memcached_client.set(full_path, value, ConfigHelperParameterStore.MEMCACHED_TTL)        

    def _get_from_parameter_store(self, full_path, is_secret=False):
        
        try:
            return self.ssm.get_parameter(Name=full_path, WithDecryption=is_secret)['Parameter']['Value']

        except ClientError as e:
            error_code = e.response['Error']['Code']

            if error_code == "ParameterNotFound":
                raise ParameterNotFoundException(message=f'Could not get parameter {full_path}: {error_code}') from e
            else:
                # Something else bad happened; better just let it through
                raise

    def _get_full_path(self, key):
        return f'/{self.environment}/{self.key_prefix}/{key}'

    # This will throw a ValueError if the parameter doesn't contain an int
    def getInt(self, key, is_secret=False):
        return int(self.get(key, is_secret))


class ParameterNotFoundException(Exception):

    '''
    Raised when a particular parameter cannot be found
    '''

    def __init__(self, message):
        logging.warn(message) # The actual parameter value isn't logged in the stack trace, so if we want to see it we need to log it here
