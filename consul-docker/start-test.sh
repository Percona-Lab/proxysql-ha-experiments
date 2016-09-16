#!/bin/bash

#help
if [ "$1" == 'help' -o "$1" == 'HELP' ]; then
        echo "
Create a Docker container that can be used to test other containers.
Usage: [ENV-VARS] start-test.sh

Options:
    servers            Number of containers to start

All environment variables are optional:
    DOCKER_LOG         Docker commands are logged in this file.
                       Default: test.docker.log
    DOCKER_NETWORK     Name of the Docker network to use.
                       Default: '' (Docker default)
    CONTAINER_NAME     Server containers prefix. Default: test
    SKIP_CONTAINER_RM  Don't remove existing containers.

If you want to use something other than the default distribution,
or use different packages:
    TEST_IMAGE         Image to use.
    PACKAGES_UPDATE    Command to update the packages list.
    PACKAGES_INSTALL   Command to install the desired packages.

Examples:
    start-test.sh
"
        exit 0
fi


. defaults.sh

# initialize docker commands log
if [ -z $DOCKER_LOG ];
then
        DOCKER_LOG='test.docker.log'
fi
echo "Logging Docker commands to $DOCKER_LOG"
echo '#'`date +"%s"` > $DOCKER_LOG

if [ ! -z $DOCKER_NETWORK ];
then
        DOCKER_NETWORK="--net=$DOCKER_NETWORK"
fi

# to support different distros

if [ -z $PACKAGES_UPDATE ];
then
        PACKAGES_UPDATE='apt-get update'
fi

if [ -z $PACKAGES_INSTALL ];
then
        PACKAGES_INSTALL='apt-get install -y iputils-ping dnsutils curl openssh-client mysql-client'
fi

# pull the image or return error
echo ''
echo "Pulling '$TEST_IMAGE' image if necessary"

cmd="docker pull $TEST_IMAGE"
echo $cmd >> $DOCKER_LOG
eval $cmd > /dev/null 2>&1
if [ $? -ne 0 ];
then
        echo "Failed to pull '$TEST_IMAGE' image. Aborting"
        exit 1
fi

if [ -z $CONTAINER_NAME ];
then
        CONTAINER_NAME='test'
fi

# remove container if exists
if [ -z $SKIP_CONTAINER_RM ]; then
        cmd="docker rm -f $CONTAINER_NAME"
        echo $cmd >> $DOCKER_LOG
        eval $cmd > /dev/null 2>&1
fi

echo ''
echo "Starting test container"

# start container
cmd="docker run -d --name=$CONTAINER_NAME \
        $DOCKER_NETWORK \
        $TEST_IMAGE \
        /bin/sh -c 'while true; do sleep 1; done'"
echo $cmd >> $DOCKER_LOG
eval $cmd > /dev/null 2>&1

if [ $? -ne "0" ];
then
        echo "ERROR: failed to start container '$proxy_name'. Aborting"
        exit 1
fi

# install basic packages
if [[ ! -z $PACKAGES_UPDATE ]];
then
        echo 'Updating packages'
        cmd="docker  exec -ti $CONTAINER_NAME $PACKAGES_UPDATE"
        echo $cmd >> $DOCKER_LOG
        eval $cmd > /dev/null 2>&1

        if [ $? -ne "0" ];
        then
                echo "ERROR: failed to install packages"
        else
                echo 'Installing packages'
                cmd="docker  exec -ti $CONTAINER_NAME $PACKAGES_INSTALL"
                echo $cmd >> $DOCKER_LOG
                eval $cmd > /dev/null 2>&1
                if [ $? -ne "0" ];
                then
                        echo "ERROR: failed to start container '$proxy_name'. Aborting"
                        exit 1
                fi
        fi
fi

echo ''
echo "Running test container:"
docker ps | grep "\b$CONTAINER_NAME"

