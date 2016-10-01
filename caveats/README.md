#Caveats

This file exists to point caveats that you may find when running Consul & ProxySQL, expecially if they are not clear from
the official documentation.


##Consul caveats

These caveats are relative to Consul in general, and not to ProxySQL in particular.


###Register / Deregister

* Registering a check in the catalog has no practical effect. The check must be registered into at least one client,
using the agent endpoint.

* You register a service (or a check) into the catalog, which is global, but you always deregister from the local node.
To completely deregistering a node, you should run a command against all nodes.

