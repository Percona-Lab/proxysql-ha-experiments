#consul-docker

This directory contains a collection of BASH scripts to easily manage Consul cluster and ProxySQL containers in Docker.
It is possible to create ProxySQL containers, a Consul cluster and a minimal container with the tools to test ProxySQL
and Consul. It is possible to register services in Consul.

More features will probably be added.

## Purpose

This collection of scripts has been created to easily setup a Consul cluster and explore how it works. However
it could become a tools to greatly speed up administrative operations in a simple envionment.

## Philosophy

This toolkit has the following characteristics.

No port is published, thus the containers must be on the same host. We may change this to explore multi-host challanges.
But when you have multiple containers of the same type and you publish the ports, you have to use non-standard ports.
This problem can be solved by Consul, but what about the Consul containers themselves?

All commands must be high-level. The users should never be forced to find a container's IP or port just to use them
in a command: the scripts must get this information automatically.

Given the purpose of this toolkit (learning), it is very verbose. It always tells what's it's doing to stdout. All Docker
commands are logged to be able to reproduce them with variations.

Simplicity. For example, it would be very elegant to have ```script.sh --param=value``` but for simplicity
we use ```PARAM=value bash script.sh```.

Failure tolerant. Of course we stop if a Consul server doesn't start. But if a Consul client doesn't start, we inform
the user and continue.

## Scripts

<dl>
  <dt><code>start-consul.sh</code></dt>
  <dd>Setup a Consul cluster in Docker, with the specified number of servers and clients.</dd>

  <dt><code>stop-consul.sh</code></dt>
  <dd>Gracefully stop a Consul node and its container.</dd>
  
  <dt><code>start-proxysql.sh</code></dt>
  <dd>Create specified number of ProxySQL containers.</dd>
  
  <dt><code>start-test.sh</code></dt>
  <dd>Create a container with clients needed to test ProxySQL and Consul: ping, dig, curl, ssh, mysql.</dd>
  
  <dt><code>register-consul.sh</code></dt>
  <dd>Register any type of service in Consul. Still a bit tricky to use, will improve so that one doesn't need
  to specify service IP or even a running Consul client. We also need a "proxy" container to run curl, use
  test.</dd>
  
  <dt><code>cleanup.sh</code></dt>
  <dd>Destroy containers created with other scripts.</dd>
</dl>

## Examples

Create 2 ProxySQL containers:
```
bash start-proxysql.sh 2
```

Setup a Consul cluster with 3 servers and 4 clients:
```
bash start-consul.sh 3 4
```

You know that the cluster is up if the scripts ends with an output like this:
```
Raft info:
Node     ID               Address          State     Voter
agent-3  172.19.0.7:8300  172.19.0.7:8300  follower  true
agent-2  172.19.0.6:8300  172.19.0.6:8300  follower  true
agent-1  172.19.0.4:8300  172.19.0.4:8300  leader    true
```
These are the cluster servers, and one of them must be in "leader" state.

Create a test container:
```
bash start-test.sh
```

Delete all above containers:
```
bash cleanup.sh
```

Manually register a service:
```
CONSUL_CONTAINER=consul-client-1 CONTAINER_ID='proxysql-1' NEWSERV_PORT='3306' NEWSERV_SERVICE_NAME='db' NEWSERV_TAGS='db' bash register-services.sh consul-client-1
```

Stop and restart a container:
```
$ docker exec consul-server-1 consul members
Node     Address          Status  Type    Build  Protocol  DC
agent-1  172.19.0.2:8301  alive   server  0.7.0  2         dc1
agent-2  172.19.0.3:8301  alive   server  0.7.0  2         dc1
agent-3  172.19.0.4:8301  alive   server  0.7.0  2         dc1
agent-4  172.19.0.6:8301  alive   client  0.7.0  2         dc1
agent-5  172.19.0.7:8301  alive   client  0.7.0  2         dc1
$ bash stop-consul.sh consul-client-1
Logging Docker commands to consul-activity.docker.log
$ docker exec consul-server-1 consul members
Node     Address          Status  Type    Build  Protocol  DC
agent-1  172.19.0.2:8301  alive   server  0.7.0  2         dc1
agent-2  172.19.0.3:8301  alive   server  0.7.0  2         dc1
agent-3  172.19.0.4:8301  alive   server  0.7.0  2         dc1
agent-4  172.19.0.6:8301  left    client  0.7.0  2         dc1
agent-5  172.19.0.7:8301  alive   client  0.7.0  2         dc1
$ docker start consul-client-1 
consul-client-1
$ docker exec consul-server-1 consul members
Node     Address          Status  Type    Build  Protocol  DC
agent-1  172.19.0.2:8301  alive   server  0.7.0  2         dc1
agent-2  172.19.0.3:8301  alive   server  0.7.0  2         dc1
agent-3  172.19.0.4:8301  alive   server  0.7.0  2         dc1
agent-4  172.19.0.6:8301  alive   client  0.7.0  2         dc1
agent-5  172.19.0.7:8301  alive   client  0.7.0  2         dc1

```

