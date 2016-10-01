#!/bin/bash

# help
if [ "$1" == 'help' -o "$1" == 'HELP' ]; then
        echo "
Register containers of a certain type in Consul.
Usage: [ENV-VARS] consul-register-services.sh
    CONSUL_CONTAINER   Name of a Consul client container.
    CONSUL_HOST        Consul client IP/hostname
    CONSUL_PORT        Consul client port, use if non-standard

CONSUL_CONTAINER and CONSUL_HOST cannot be specified together.

All environment variables are optional:
    TEMPDIR            Where temporary files are written.
    DOCKER_LOG         Docker commands are logged in this file.
                       Default: consul-activity.docker.log.

Specify the containers with the services:
    CONTAINER_ID       Delete a single container with this ID.
    SERVICES_IMAGE     Register containers built from this image.
    SERVICES_NAME      Register containers whose name contains this string.
    PROXY_CONTAINER    Name of the container that will run curl.
                       Must be in the same Docker network as Consul.
                       If empty, curl will be ran on local host.
                       Default: 'test'.

SERVICES_IMAGE and SERVICES_NAME can be used together.
CONTAINER_ID cannot.

Specify new services data:
    NEWSERV_PORT       Port used for all containers.
    NEWSERV_SERVICE_ID Service ID.
    NEWSERV_SERVICE_NAME
                       Service name.
    NEWSERV_TAGS       Service tags.

Examples:
    PROXY_CONTAINER=test SERVICES_IMAGE='perconalab/proxysql' consul-register-services.sh 144.0.0.1
    PROXY_CONTAINER='' SERVICES_NAME='proxysql' consul-register-services.sh 144.0.0.1 5000
"
        exit 0
fi


# include configuration
. conf/scripts/common.cnf
. conf/scripts/consul.cnf
. conf/scripts/test.cnf
. defaults.sh


# get params

if [ -z $CONTAINER_ID ];
then
        echo "ERROR: CONTAINER_ID must be specified"
        exit 1
fi

if [ ! -z $CONSUL_CONTAINER ];
then
        if [ ! -z $CONSUL_HOST ];
        then
                echo "ERROR: CONSUL_HOST and CONSUL_CONTAINER cannot be specified together"
                exit 1
        fi

        CONSUL_HOST=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONSUL_CONTAINER)
        if [ -z CONSUL_HOST ]; then
                CONSUL_HOST=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}' $CONSUL_CONTAINER)
        fi
elif [ ! -z $CONSUL_HOST ];
then
        echo "ERROR: CONSUL_HOST or CONSUL_CONTAINER must be specified"
        exit 1
fi

if [ -z $CONSUL_PORT ];
then
        CONSUL_PORT='8500'
fi

if [ -z $NEWSERV_SERVICE_ID ];
then
        NEWSERV_SERVICE_ID=$CONTAINER_ID
fi

# initialize docker commands log
if [ -z $DOCKER_LOG ];
then
        DOCKER_LOG='consul-activity.docker.log'
fi


echo "Logging Docker commands to $DOCKER_LOG"
touch $DOCKER_LOG
echo '#'`date +"%s"` >> $DOCKER_LOG


# get container's IP from ID
newserv_ip=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_ID)
if [ -z newserv_ip ]; then
        newserv_ip=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}' $CONTAINER_ID)
fi

echo "Registering $newserv_ip on host $CONSUL_HOST"
cmd=''
if [ ! -z $PROXY_CONTAINER ];
then
        cmd="docker exec -ti $PROXY_CONTAINER"
fi
cmd="$cmd curl -H \"Content-Type: application/json\" -X PUT -d \"
        {
                \\\"ID\\\":         \\\"$NEWSERV_SERVICE_ID\\\",
                \\\"Name\\\":       \\\"$NEWSERV_SERVICE_NAME\\\",
                \\\"Address\\\":    \\\"$newserv_ip\\\",
                \\\"Port\\\":       $NEWSERV_PORT
        }
        \" http://$CONSUL_HOST:$CONSUL_PORT/v1/agent/service/register"

# it's possible that this is not a docker command, but log it anyway
echo $cmd >> $DOCKER_LOG
eval $cmd > /dev/null 2>&1

if [ $? -ne "0" ];
then
        echo "ERROR: command failed: $cmd"
fi

checks_file="./conf/consul/checks/$CONTAINER_ID"
if [ -f $checks_file -o -L $checks_file ];
then
        # support for checks to be added soon
        echo 1 > /dev/null
fi

