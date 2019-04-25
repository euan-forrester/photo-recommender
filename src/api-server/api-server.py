#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
from confighelper import ConfigHelper

#
# Read in commandline arguments
#

parser = argparse.ArgumentParser(description="Serve API requests from the favorites database")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="api-server")

database_username   = config_helper.get("database-username")
database_password   = config_helper.get("database-password", is_secret=True)
database_host       = config_helper.get("database-host")
database_port       = config_helper.getInt("database-port")
database_name       = config_helper.get("database-name")
