#Consul caveats

##Deregistering

You register a service (or a check) into the catalog, which is global, but you always deregister from the local node.
To completely deregistering a node, you should run a command against all nodes.

