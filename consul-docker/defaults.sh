# This file sets global defaults for all scripts that use them.
# Variables can be overridden first or after including this file.
# If a variable refers to a particular image, it should begin with its name uppercase (eg: PROXYSQL_*).

# WARNING: DON'T CHANGE THESE VALUES
# This could cause problems.
# All these values are just defaults, and can be configured elsewhere.


# ProxySQL related

# by default, use perconalab image
if [ -z $PROXYSQL_IMAGE ];
then
        PROXYSQL_IMAGE='perconalab/proxysql'
fi


# Consul related

# by default, use official image
if [ -z $CONSUL_IMAGE ];
then
        CONSUL_IMAGE='consul'
fi

# local path mapped to containers volumes
if [ -z $CONSUL_LOCAL_PATH ];
then
        CONSUL_LOCAL_PATH="$HOME/docker/$CONSUL_IMAGE"
fi


# test container

# by default, ubuntu
if [ -z $TEST_IMAGE ];
then
        TEST_IMAGE='ubuntu'
fi

if [ -z $TEST_CONTAINER_NAME ];
then
        TEST_CONTAINER_NAME='test'
fi


# common

# containers will be created in this network
if [ -z $DOCKER_NETWORK ];
then
        # perconalab's default net
        DOCKER_NETWORK='Theistareykjarbunga_net'
fi

# container used to execute commands like curl against Consul
if [ -z $PROXY_CONTAINER ];
then
        PROXY_CONTAINER=$TEST_CONTAINER_NAME
fi

# containers configuration files path
if [ -z $CONFIG_DIR ];
then
        CONFIG_DIR="$HOME/docker/$CONSUL_IMAGE"
fi

