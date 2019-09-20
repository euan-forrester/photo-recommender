#!/bin/sh

if [ $# -lt 2 ]; then
    echo "Usage: loop_command.sh <command to run> <seconds to sleep in between>"
    exit 0
fi

while true
do
    echo "loop_command.sh: Beginning command $1"
    eval "$1"
    echo "loop_command.sh: Finished command. Sleeping for $2"
    sleep $2
done