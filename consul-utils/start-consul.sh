# load configuration
. conf.sh

cmd="$CONSUL_PATH/consul agent -config-file=$CONSUL_CONF_FILE"

if [ ! -z $JOIN_NODE ];
then
	$cmd="$cmd -join=$JOIN_NODE"
fi

if [ -z $CONSUL_LOG ];
then
	echo "Starting with command: $cmd &"
	$cmd &
else
	echo "Starting with command: $cmd >> $CONSUL_LOG &"
	$cmd >> $CONSUL_LOG &
fi

