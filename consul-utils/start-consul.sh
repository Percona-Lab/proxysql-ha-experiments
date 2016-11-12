# load configuration
. conf.sh

cmd="$CONSUL_PATH/consul agent -config-file=$CONSUL_CONF_FILE"
echo "Starting with command: $cmd"
if [ -z $CONSUL_LOG ];
then
	$cmd &
else
	$cmd >> $CONSUL_LOG &
fi

