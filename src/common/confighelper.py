import configparser
import boto3
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
        return self.config.get(self.environment, key)

    def getInt(self, key, is_encrypted=False):
        return self.config.getint(self.environment, key)

class ConfigHelperParameterStore:

    '''
    Reads config items from the AWS Parameter Store
    '''

    def __init__(self, environment, key_prefix):
        self.environment    = environment
        self.key_prefix     = key_prefix
        self.ssm            = boto3.client('ssm') # Region is read from the AWS_DEFAULT_REGION env var

    def get(self, key, is_encrypted=False):
        return self.ssm.get_parameter(Name='/%s/%s/%s' % (self.environment, self.key_prefix, key), WithDecryption=is_encrypted)['Parameter']['Value']

    def getInt(self, key, is_encrypted=False):
        return int(self.get(key, is_encrypted))