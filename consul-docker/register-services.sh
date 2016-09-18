#!/bin/bash

# help
if [ "$1" == 'help' -o "$1" == 'HELP' ]; then
        echo "
Register containers of a certain type in Consul.
Usage: [ENV-VARS] consul-register-services.sh [consul-host] <consul-port>
    consul-host        Consul client IP/hostname
    consul-port        Consul client port, use if non-standard

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


# Register a service in Consul.
function register_container {
        host=$1
        port=$2
        proxy_container=$3
        newserv_container_id=$4
        newserv_port=$5
        newserv_id=$6
        newserv_name=$7
        newserv_tags=$8

        # get container's IP from ID
        ip=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $newserv_container_id)
        if [ -z ip ]; then
                ip=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}' $newserv_container_id)
        fi
        
        echo "Registering $ip"
        cmd=''
        if [ ! -z $proxy_container ];
        then
                cmd="docker exec -ti $proxy_container"
        fi
        cmd="$cmd curl http://$host:$port/v1/catalog/service/web \
                [
                    {
                        \"Node\":         \"$newserv_container_id\", \
                        \"Address\":      \"$ip\", \
                        \"ServiceID\":    \"$newserv_id\", \
                        \"ServiceName\":  \"$newserv_name\", \
                        \"ServiceTags\":  [\"$newserv_tags\"], \
                        \"ServicePort\":  $newserv_port
                    }
                ]"

        echo $cmd
        # it's possible that this is not a docker command, but log it anyway
        echo $cmd > DOCKER_LOG
        eval $cmd > /dev/null 2>&1

        if [ $? -ne "0" ];
        then
                echo "ERROR: failed to start container '$proxy_name'. Aborting"
                exit 1
        fi
}


# get params
consul_host=$1
consul_port=$2
if [ ! -z $consul_port ];
then
        consul_port='8600'
fi

. defaults.sh


# single service
if [ ! -z $CONTAINER_ID ];
then
        if [ ! -z $SERVICES_IMAGE -o ! -z $SERVICES_NAME ];
        then
                echo 'ERROR: CONTAINER_ID cannot be combined with SERVICES_IMAGE or SERVICES_NAME. Aborting'
                exit 1
        fi
        register_container $consul_host $consul_port $PROXY_CONTAINER $CONTAINER_ID $NEWSERV_PORT $NEWSERV_SERVICE_ID $NEWSERV_SERVICE_NAME $NEWSERV_TAGS
        exit 0
fi


# services matching given filter(s)
if [ -z $TEMPDIR ];
then
        TEMPDIR='~/temp'
fi
mkdir -p $TEMPDIR > /dev/null 2>&1

# initialize docker commands log
if [ -z $DOCKER_LOG ];
then
        DOCKER_LOG='consul-activity.docker.log'
fi
echo "Logging Docker commands to $DOCKER_LOG"
touch $DOCKER_LOG
echo '#'`date +"%s"` >> $DOCKER_LOG

filter=''
if [ ! -z $SERVICES_IMAGE ];
then
        filter="$filter --filter 'ancestor=$SERVICES_IMAGE'"
fi
if [ ! -z $SERVICES_NAME ];
then
        filter="$filter --filter 'name=$SERVICES_NAME'"
fi

# write the services to remove into a temp file
tempfile="$TEMPDIR/consul-register"
cmd="docker ps $filter | tail -n +2 | awk '{ print \$1 }'"
eval $cmd > $tempfile

while read id; do
        register_container $consul_host $consul_port $PROXY_CONTAINER $id $NEWSERV_PORT $NEWSERV_SERVICE_ID $NEWSERV_SERVICE_NAME $NEWSERV_TAGS
done < $tempfile

# remove temp files
rm $tempfile

