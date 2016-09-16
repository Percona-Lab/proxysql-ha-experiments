#!/bin/bash

function rm_container {
        IMAGE_NAME=$1
        LOCAL_PATH=$2

        echo "Removing containers created from image $IMAGE_NAME"
        docker rm -f $(docker ps -a | grep -i "$IMAGE_NAME" | awk '{print $1}') > /dev/null 2>&1
        
        if [ ! -z $LOCAL_PATH ];
        then
                echo "Deleting directory: $LOCAL_PATH"
                rm -Rf $LOCAL_PATH
        fi
}


. defaults.sh

rm_container $CONSUL_IMAGE "$CONSUL_LOCAL_PATH/$CONSUL_IMAGE"
rm_container $PROXYSQL_IMAGE ''
rm_container $TEST_IMAGE ''

