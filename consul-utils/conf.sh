#  Paths
#  =====

# user who runs consul daemon
CONSUL_USER='consul'
# file to download from consul site
CONSUL_ARCHIVE='consul_0.7.1_linux_amd64.zip'
# where consul executable should be placed
CONSUL_PATH='/usr/local/bin'
# contains main consul config file
CONSUL_CONF_FILE='/etc/consul.cnf'
# contains configuration for services
CONSUL_CONF_DIR='/etc/consul.d'
# consul datadir
CONSUL_DATA_DIR='/var/consul'
# stdout and stderr will be redirected here
CONSUL_LOG='/var/log/consul.log'


#  Consul Parameters
#  =================

# ID of the Consul instance
AGENT_ID='1'
# datacenter name
DC_NAME='dc1'
# datacenter size at startup
DC_SIZE='1'
# log verbosity
LOG_LEVEL='DEBUG'

