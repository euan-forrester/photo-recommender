#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
from flask import Flask
from confighelper import ConfigHelper

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

database_username   = config_helper.get("database-username")
database_password   = config_helper.get("database-password", is_secret=True)
database_host       = config_helper.get("database-host")
database_port       = config_helper.getInt("database-port")
database_name       = config_helper.get("database-name")
server_host         = config_helper.get("server-host")
server_port         = config_helper.getInt("server-port")

#
# Run our API server
#
# Note that the Flask built-in server is not sufficient for production. In production we run under gunicorn instead, and
# we run behind nginx. See: 
#   https://medium.com/@kmmanoj/deploying-a-scalable-flask-app-using-gunicorn-and-nginx-in-docker-part-1-3344f13c9649
#

application = Flask(__name__)

@application.route("/")
def hello():
    return "Hello World!"

if __name__ == '__main__':
    # Note that running Flask like this results in the output saying "lazy loading" and I'm not sure what that means.
    # If we run it the way specified in the documentation `FLASK_APP=./api-server.py flask run` then it doesn't say this.
    # But I wanted to be able to specify the port via a parameter rather than having to use an env var
    application.run(host=server_host, port=server_port)