#Caveats

This file exists to point caveats that you may find when running Consul & ProxySQL, expecially if they are not clear from
the official documentation.


##Consul caveats

These caveats are relative to Consul in general, and not to ProxySQL in particular.


###Services

* Registering a check in the catalog has no practical effect. The check must be registered into at least one client,
using the agent endpoint.


###Checks

* You register a service (or a check) into the catalog, which is global, but you always deregister from the local node.
To completely deregistering a node, you should run a command against all nodes.

* A client is responsible for its own checks. If it dies, no one will do those checks. Normally it isn't huge problem,
because a client runs on a service's machine. But with Docker, usually a client has its own container. Thus, keep some
check redundancy.


##Consul and ProxySQL

* mysqladmin and mysql exit with code 1 when they can't connect to mysqld. For Consul checks this is a warning,
not a critical error.

