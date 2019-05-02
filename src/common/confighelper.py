import configparser
import boto3
from botocore.exceptions import ClientError
import logging
import os

class ConfigHelper:
    
    @staticmethod
    def get_config_helper(default_env_name, aws_parameter_prefix):
        if not "ENVIRONMENT" in os.environ:
            logging.info("Did not find ENVIRONMENT environment variable, running in development mode and loading config from config files.")

            return ConfigHelperFile(environment=default_env_name, filename_list=["config/config.ini", "config/secrets.ini"])

        else:
            ENVIRONMENT = os.environ.get('ENVIRONMENT')

            logging.info("Found ENVIRONMENT environment variable containing '%s': assuming we're running in AWS and getting our parameters from the AWS Parameter Store" % (ENVIRONMENT))

            return ConfigHelperParameterStore(environment=ENVIRONMENT, key_prefix=aws_parameter_prefix)

    @staticmethod
    def _log_int(param, value, is_secret):
        if is_secret:
            logging.info("Got parameter %s with value <secret>" % (param))
        else:
            logging.info("Got parameter %s with value %d" % (param, value))

    @staticmethod
    def _log_str(param, value, is_secret):
        if is_secret:
            logging.info("Got parameter %s with value <secret>" % (param))
        else:
            logging.info("Got parameter %s with value %s" % (param, value))


class ConfigHelperFile(ConfigHelper):
    
    '''
    Uses the ConfigParser library to read config items from a set of local files
    '''

    def __init__(self, environment, filename_list):
        self.environment    = environment
        self.config         = configparser.ConfigParser()

        for filename in filename_list:
            logging.info("Reading in config file '%s'" % filename)
            self.config.read(filename)

    def get(self, key, is_secret=False):
        try:
            value = self.config.get(self.environment, key)
            ConfigHelper._log_str(key, value, is_secret)
            return value

        except configparser.NoOptionError as e:
            raise ParameterNotFoundException(message='Could not get parameter %s' % (key)) from e

    # This will throw a ValueError if the parameter doesn't contain an int
    def getInt(self, key, is_secret=False):
        try:
            value = self.config.getint(self.environment, key)
            ConfigHelper._log_int(key, value, is_secret)
            return value

        except configparser.NoOptionError as e:
            raise ParameterNotFoundException(message='Could not get parameter %s' % (key)) from e

class ConfigHelperParameterStore(ConfigHelper):

    '''
    Reads config items from the AWS Parameter Store
    '''

    def __init__(self, environment, key_prefix):
        self.environment    = environment
        self.key_prefix     = key_prefix
        self.ssm            = boto3.client('ssm') # Region is read from the AWS_DEFAULT_REGION env var

    def get(self, key, is_secret=False):
        
        full_path = '/%s/%s/%s' % (self.environment, self.key_prefix, key)

        try:
            value = self.ssm.get_parameter(Name=full_path, WithDecryption=is_secret)['Parameter']['Value']
            ConfigHelper._log_str(full_path, value, is_secret)
            return value

        except ClientError as e:
            error_code = e.response['Error']['Code']

            if error_code == "ParameterNotFound":
                raise ParameterNotFoundException(message='Could not get parameter %s: %s' % (full_path, error_code)) from e
            else:
                # Something else bad happened; better just let it through
                raise

    # This will throw a ValueError if the parameter doesn't contain an int
    def getInt(self, key, is_secret=False):
        return int(self.get(key, is_secret))


class ParameterNotFoundException(Exception):

    '''
    Raised when a particular parameter cannot be found
    '''

    def __init__(self, message):
        logging.warn(message) # The actual parameter value isn't logged in the stack trace, so if we want to see it we need to log it here
