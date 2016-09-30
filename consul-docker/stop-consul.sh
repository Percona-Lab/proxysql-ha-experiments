#!/bin/bash

# help
if [ "$1" == 'help' -o "$1" == 'HELP' ]; then
        echo "
Gracefully stop a Consul node and its container.
Usage: stop-consul.sh <container-name>
    container-name     Name of the container to stop.
    DOCKER_LOG         Docker commands are logged in this file.
                       Default: consul-activity.docker.log.

Examples:
    stop-consul.sh consul-client-1
"
        exit 0
fi

# get params

. conf/scripts/common.cnf
. conf/scripts/consul.cnf
. defaults.sh

container_name=$1

# validate input

if [ -z $container_name ];
then
		echo "ERROR: container_name must be specified"
		exit 1
fi

if [ -z $DOCKER_LOG ];
then
        DOCKER_LOG='consul-activity.docker.log'
fi

# initialize docker commands log
echo "Logging Docker commands to $DOCKER_LOG"
touch $DOCKER_LOG
echo '#'`date +"%s"` >> $DOCKER_LOG

# leave consul cluster
cmd="docker exec $container_name consul leave"
echo $cmd >> $DOCKER_LOG
eval $cmd > /dev/null 2>&1

if [ $? -ne "0" ];
then
        echo "ERROR: failed to gracefully leave the cluster. Aborting"
        exit 1
fi

# stop the container
sleep 1
cmd="docker stop $container_name"
echo $cmd >> $DOCKER_LOG
eval $cmd > /dev/null 2>&1

if [ $? -ne "0" ];
then
        echo "ERROR: failed to stop the container. Aborting"
        exit 1
fi

