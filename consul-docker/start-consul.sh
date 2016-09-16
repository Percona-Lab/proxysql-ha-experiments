#!/bin/bash

# help
if [ "$1" == 'help' -o "$1" == 'HELP' ]; then
        echo "
Start a Consul cluster in Docker.
Usage: [ENV-VARS] start-consul.sh [servers] [clients]

Options:
    servers            Number of servers to start
    clients            Number of clients to start

All environment variables are optional:
    DOCKER_LOG         Docker commands are logged in this file.
                       Default: consul.docker.log
    DOCKER_NETWORK     Name of the Docker network to use.
                       Default: '' (Docker default)
    CONFIG_DIR         Directory with configuration files used for all containers:
                       consul.conf, server.conf, client.conf
    CONSUL_LOCAL_PATH  Containers directories are mapped to this local path.
                       Default: ~/docker/<CONSUL_IMAGE>
    CONSUL_IMAGE       Name of the image to use. Default: consul
    SKIP_IMAGE_PULL    Don't execute docker pull.
                       Use this if the image is local or you don't want
                       to update it.
    SERVER_CONTAINER_NAME
                       Server containers prefix. Default: docker-server
    CLIENT_CONTAINER_NAME
                       Client containers prefix, or complete name when starting
                       only 1 client.
                       Default: docker-client
    SKIP_CONTAINER_RM  Don't remove existing containers.

Examples:
    SKIP_CONTAINER_RM=1 start-consul.sh 3 2
"
        exit 0
fi


# IP of 1st server
declare node1


# prepare environment

IFS=" "

. defaults.sh

# initialize docker commands log
if [ -z $DOCKER_LOG ];
then
        DOCKER_LOG='consul.docker.log'
fi
echo "Logging Docker commands to $DOCKER_LOG"
echo '#'`date +"%s"` > $DOCKER_LOG

if [ ! -z $DOCKER_NETWORK ];
then
        DOCKER_NETWORK="--net=$DOCKER_NETWORK"
fi

# pull the image or return error
if [ -z $SKIP_IMAGE_PULL ];
then
        echo ''
        echo "Pulling '$CONSUL_IMAGE' image if necessary"

        cmd="docker pull $CONSUL_IMAGE"
        echo $cmd >> $DOCKER_LOG
        eval $cmd > /dev/null 2>&1
        if [ $? -ne 0 ];
        then
                echo "Failed to pull '$CONSUL_IMAGE' image. Aborting"
                exit 1
        fi
fi

# Server config and client config have a common part.
# Read that part and replace 'INCLUDE' with the specific file.
file_content_server=''
file_content_client=''
if [ ! -z $CONFIG_DIR ];
then
        if [ -d $CONFIG_DIR -o -L $CONFIG_DIR ];
        then
                file_content_server=$(cat $CONFIG_DIR/consul.common.conf)$(cat $CONFIG_DIR/consul.server.conf)'}'
                file_content_client=$(cat $CONFIG_DIR/consul.common.conf)$(cat $CONFIG_DIR/consul.client.conf)'}'
        else
                echo 'ERROR: CONFIG_DIR not found or not a directoy. Aborting'
                exit 1
        fi
fi


# start servers

# index
i="1"
# specified by user
u=$1
# unique agent ID
agent_id="1"

if [ -z $u ];
then
        echo 'Number of Consul server containers not specified; abort'
        exit 1
fi

if [ $((u%2)) -eq 0 -o $u -lt 3 ];
then
        echo 'There must be at least 3 Consul servers and their number must be even'
        exit 1
fi

if [ -z $SERVER_CONTAINER_NAME ];
then
        SERVER_CONTAINER_NAME='consul-server'
fi

echo ''
echo "Starting $u Consul server containers"

while [ $i -le $u ]
do
        consul_name="$SERVER_CONTAINER_NAME-$i"
        echo $consul_name

        container_path="$CONSUL_LOCAL_PATH/$consul_name"

        # remove container if exists
        if [ -z $SKIP_CONTAINER_RM ];
        then
                cmd="docker rm -f $consul_name"
                echo $cmd >> $DOCKER_LOG
                eval $cmd > /dev/null 2>&1

                rm -Rf $container_path
        fi

        # add conf JSON, after replacing macros
        if [[ ! -z $file_content_server ]];
        then
                node_conf=$file_content_server
                node_conf="${node_conf/'::agent_id::'/$agent_id}"
                node_conf="${node_conf/'::dc_size::'/$u}"
        else
                node_conf='{ }'
        fi

        if [ $i = "1" ];
        then
                # start first server and remember its IP
                
                cmd="docker run --name=$consul_name $DOCKER_NETWORK -v $container_path/config:/consul/config -d -e 'CONSUL_LOCAL_CONFIG=$node_conf' $CONSUL_IMAGE agent -server"
                echo $cmd >> $DOCKER_LOG
                eval $cmd > /dev/null 2>&1

                if [ $? -ne "0" ];
                then
                        echo "ERROR: failed to start container '$proxy_name'. Aborting"
                        exit 1
                fi

                # get ip
                # first, get node id
                node1_id=$(docker ps | grep $consul_name | awk '{print $1}')
                # this will work if not in a Docker network
                node1_ip=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $node1_id)
                # hopefully this will work in all other cases
                if [ -z node1_ip ]; then
                        node1_ip=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}' $node1_id)
                fi
                
                node1_name=$consul_name
                server_ip_list=$node1_ip
        else
                # start container and join first server
                cmd="docker run --name=$consul_name $DOCKER_NETWORK -v $container_path/config:/consul/config -d -e 'CONSUL_LOCAL_CONFIG=$node_conf' $CONSUL_IMAGE agent -server -join=$node1_ip" >> $DOCKER_LOG
                echo $cmd >> $DOCKER_LOG
                eval $cmd > /dev/null 2>&1
                if [ $? -ne "0" ];
                then
                        echo "ERROR: failed to start container '$proxy_name'. Aborting"
                        exit 1
                fi
                cur_node_ip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $(docker ps | grep $consul_name | awk '{print $1}'))
                server_ip_list="$server_ip_list $cur_node_ip"
        fi

        agent_id=$[$agent_id+1]
        i=$[$i+1]
done

echo ''
echo 'Joining cluster...'
# after all nodes are started, we can join them
echo "docker exec $node1_name consul join $server_ip_list" >> $DOCKER_LOG
docker exec $node1_name consul join $server_ip_list > /dev/null 2>&1
if [ $? -eq "0" ];
then
        echo "Cluster successfully joined"
else
        echo 'ERROR: failed to start cluster. You will need to do this manually.'
        echo 'Command used:'
        echo "docker exec $node1_name consul join $server_ip_list"
fi


# start clients

# index
i="1"
# specified by user
u=$2

if [ -z $2 ];
then
        echo 'Number of Consul client containers not specified; assuming 1'
        i=1
        u=1
fi

if [ -z $CLIENT_CONTAINER_NAME ];
then
        CLIENT_CONTAINER_NAME='consul-client'
fi

echo ''
echo "Starting $u Consul client containers"

while [ $i -le $u ]
do
        if [ $u = "1" ];
        then
                consul_name=$CLIENT_CONTAINER_NAME
        else
                consul_name="$CLIENT_CONTAINER_NAME-$i"
        fi

        echo $consul_name
        container_path="$CONSUL_LOCAL_PATH/$consul_name"

        # remove container if already exists
        if [ -z $SKIP_CONTAINER_RM ];
        then
                cmd="docker rm -f $consul_name"
                echo $cmd >> $DOCKER_LOG
                eval $cmd > /dev/null 2>&1

                rm -Rf $container_path
        fi

        # add conf JSON, like we did for server agents
        if [[ ! -z $file_content_client ]];
        then
                node_conf=$file_content_client
                node_conf="${node_conf/'::agent_id::'/$agent_id}"
                node_conf="${node_conf/'::dc_size::'/$u}"
        else
                node_conf='{ }'
        fi

        # start container and join first server
        cmd="docker run --name=$consul_name $DOCKER_NETWORK -v $container_path/config:/consul/config -d -e 'CONSUL_LOCAL_CONFIG=$node_conf' $CONSUL_IMAGE agent -join=$node1_ip"
        echo $cmd >> $DOCKER_LOG
        eval $cmd > /dev/null 2>&1
        
        if [ $? -ne "0" ];
        then
                echo "ERROR: failed to start container '$proxy_name'"
        fi

        agent_id=$[$agent_id+1]
        i=$[$i+1]
done


# show info about containers

sleep 1
echo ''
echo "Running Consul containers:"
docker ps | grep "\b$SERVER_CONTAINER_NAME\|\b$CLIENT_CONTAINER_NAME"
echo ''
echo "Consul cluster members:"
docker exec -t $SERVER_CONTAINER_NAME-1 consul members -detailed

