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

## Examples

Create 2 ProxySQL containers:
```
bash start-proxysql.sh 2
```

Setup a Consul cluster with 3 servers and 4 clients:
```
bash start-consul.sh 3 4
```

Create a test container:
```
bash start-test.sh
```

Delete all above containers:
```
bash cleanup.sh
```

