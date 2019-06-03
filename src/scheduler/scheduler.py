#!/usr/bin/env python3

import sys
sys.path.insert(0, '../common')

import argparse
import logging
import os
from queuewriter import SQSQueueWriter
from queuereader import SQSQueueReader
from confighelper import ConfigHelper

#
# Read in commandline arguments
#

parser = argparse.ArgumentParser(description="Schedule pulling of various users' data")

parser.add_argument("-d", "--debug", action="store_true", dest="debug", default=False, help="Display debug information")

args = parser.parse_args()

log_level = logging.INFO
if args.debug:
    log_level = logging.DEBUG

logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

#
# Get our config
#

config_helper = ConfigHelper.get_config_helper(default_env_name="dev", aws_parameter_prefix="puller-flickr")

api_server_host                     = config_helper.get("api-server-host")
api_server_port                     = config_helper.getInt("api-server-port")
api_server_fetch_batch_size         = config_helper.getInt("api-server-fetch-batch-size")

scheduler_queue_url                 = config_helper.get("scheduler-queue-url")
scheduler_queue_batch_size          = config_helper.getInt("scheduler-queue-batchsize")

scheduler_response_queue_url        = config_helper.get("scheduler-response-queue-url")
scheduler_response_queue_batch_size = config_helper.getInt("scheduler-response-queue-batchsize")
scheduler_response_queue_max_items_to_process = config_helper.getInt("scheduler-response-queue-maxitemstoprocess")
