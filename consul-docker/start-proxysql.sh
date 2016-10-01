#!/bin/bash

#help
if [ "$1" == 'help' -o "$1" == 'HELP' ]; then
        echo "
Start multiple ProxySQL Docker containers.
Usage: [ENV-VARS] start-proxysql.sh [servers]

Options:
    servers            Number of containers to start

All environment variables are optional:
    DOCKER_LOG         Docker commands are logged in this file.
                       Default: proxysql.docker.log
    DOCKER_NETWORK     Name of the Docker network to use.
                       Default: '' (Docker default)
    PROXYSQL_IMAGE     Name of the image to use. Default: perconalab/proxysql
    SKIP_IMAGE_PULL    Don't execute docker pull.
                       Use this if the image is local or you don't want
                       to update it.
    CONTAINER_NAME     Server containers prefix. Default: proxysql
    SKIP_CONTAINER_RM  Don't remove existing containers.

    CONSUL_CONTAINER   The service will be registered into this Consul node.
                       Leave empty to avoid registration.
    SERVICE_NAME       The service will be registered in Consul with this name.

Examples:
    SKIP_CONTAINER_RM=1 start-proxysql.sh 2
"
        exit 0
fi


# index
i="1"
# specified by user
u=$1


# prepare environment

IFS=" "

# include configuration
. conf/scripts/common.cnf
. conf/scripts/proxysql.cnf
. defaults.sh


if [ -z $SERVICE_NAME ];
then
        SERVICE_NAME=$PROXYSQL_SERVICE_NAME
fi

# initialize docker commands log
if [ -z $DOCKER_LOG ]; then
        DOCKER_LOG='proxysql.docker.log'
fi
echo "Logging Docker commands to $DOCKER_LOG"
echo `date +"%s"` > $DOCKER_LOG

if [ ! -z $DOCKER_NETWORK ];
then
        DOCKER_NETWORK="--net=$DOCKER_NETWORK"
fi

# pull the image or return error
if [ -z $SKIP_IMAGE_PULL ]; then
        echo ''
        echo "Pulling '$PROXYSQL_IMAGE' image if necessary"

        cmd="docker pull $PROXYSQL_IMAGE"
        echo $cmd >> $DOCKER_LOG
        eval $cmd > /dev/null 2>&1
        if [ $? -ne 0 ];
        then
                echo "Failed to pull '$PROXYSQL_IMAGE' image. Aborting"
                exit 1
        fi
fi

if [ -z $CONTAINER_NAME ];
then
        CONTAINER_NAME='proxysql'
fi

if [ -z $u ];
then
        echo 'Number of ProxySQL containers not specified; assuming 1'
        i="1"
        u="1"
fi

echo ''
echo "Starting $u containers"

while [ $i -le $u ]
do
        if [ $u = "1" ];
        then
                proxy_name=$CONTAINER_NAME
        else
                proxy_name="$CONTAINER_NAME-$i"
        fi

        # remove container if exists
        if [ -z $SKIP_CONTAINER_RM ]; then
                cmd="docker rm -f $proxy_name"
                echo $cmd >> $DOCKER_LOG
                eval $cmd > /dev/null 2>&1
        fi

        # start container
        echo $proxy_name
        cmd="docker run -d --name=$proxy_name \
                $DOCKER_NETWORK \
                -e CLUSTER_NAME='db_cluster' \
                -e DISCOVERY_SERVICE='.' \
                $PROXYSQL_IMAGE"
        echo $cmd >> $DOCKER_LOG
        eval $cmd > /dev/null 2>&1

        if [ $? -ne "0" ];
        then
                echo "ERROR: failed to start container '$proxy_name'. Aborting"
                exit 1
        fi

        # register service in CONSUL_CONTAINER
        if [ ! -z "$CONSUL_CONTAINER" ];
        then
                checks_file="./conf/consul/checks/$NEWSERV_SERVICE_NAME"
                checks_json=$(cat $checks_file)
                checks_json="${checks_json/'::host::'/$newserv_ip}"
                checks_json="${checks_json/'::port::'/$PROXYSQL_PORT_ADMIN}"
                checks_json="${checks_json/'::user::'/$PROXYSQL_USER}"
                checks_json="${checks_json/'::password::'/$PROXYSQL_PASSWORD}"

                SKIP_CONFIG='1' \
                CHECKS=$checks_json \
                CONSUL_HOST='' \
                CONSUL_CONTAINER=$CONSUL_CONTAINER \
                CONTAINER_ID=$proxy_name \
                NEWSERV_PORT=$PROXYSQL_PORT \
                NEWSERV_SERVICE_NAME=$SERVICE_NAME \
                        . register-services.sh consul-client-1
        fi

        i=$[$i+1]
done


echo ''
echo "Running ProxySQL containers:"
docker ps | grep "\b$CONTAINER_NAME"

