import configparser
import boto3
from botocore.exceptions import ClientError
import logging

class ConfigHelperFile:
    
    '''
    Uses the ConfigParser library to read config items from a set of local files
    '''

    def __init__(self, environment, filename_list):
        self.environment    = environment
        self.config         = configparser.ConfigParser()

        for filename in filename_list:
            self.config.read(filename)

    def get(self, key, is_encrypted=False):
        try:
            return self.config.get(self.environment, key)
        except configparser.NoOptionError as e:
            raise ParameterNotFoundException(message='Could not get parameter %s' % (key)) from e

    # This will throw a ValueError if the parameter doesn't contain an int
    def getInt(self, key, is_encrypted=False):
        try:
            return self.config.getint(self.environment, key)
        except configparser.NoOptionError as e:
            raise ParameterNotFoundException(message='Could not get parameter %s' % (key)) from e

class ConfigHelperParameterStore:

    '''
    Reads config items from the AWS Parameter Store
    '''

    def __init__(self, environment, key_prefix):
        self.environment    = environment
        self.key_prefix     = key_prefix
        self.ssm            = boto3.client('ssm') # Region is read from the AWS_DEFAULT_REGION env var

    def get(self, key, is_encrypted=False):
        
        full_path = '/%s/%s/%s' % (self.environment, self.key_prefix, key)

        try:
            return self.ssm.get_parameter(Name=full_path, WithDecryption=is_encrypted)['Parameter']['Value']
        except ClientError as e:
            error_code = e.response['Error']['Code']

            if error_code == "ParameterNotFound":
                raise ParameterNotFoundException(message='Could not get parameter %s: %s' % (full_path, error_code)) from e
            else:
                # Something else bad happened; better just let it through
                raise

    # This will throw a ValueError if the parameter doesn't contain an int
    def getInt(self, key, is_encrypted=False):
        return int(self.get(key, is_encrypted))


class ParameterNotFoundException(Exception):

    '''
    Raised when a particular parameter cannot be found
    '''

    def __init__(self, message):
        logging.warn(message) # The actual parameter value isn't logged in the stack trace, so if we want to see it we need to log it here
