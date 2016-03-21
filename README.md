# Orbit Mapper

## A tool to visualize and query topologies in the Orbit Lab.

The Orbit Lab has means to set the topology in experiments via the experiment
script executed by omf, but this is a predetermined topology and doesn't offer
the ability to define topologies with nodes artificially hidden due to
obstruction or fading. Many experiments could benefit by being able to operate
on a multi-hop network, and the goal here is to offer a tool to find such a
topology.

The [FAQ on the wiki](http://www.orbit-lab.org/wiki/Documentation/FAQ) and
[referenced research](http://www.orbit-lab.org/wiki/Documentation/z2Publications#Howdoyoumapatopologyontospecificnodeassignments)
state that multi-hop topologies are best found by noise injection. This tool
does not itself create any given topology, but determines the connectedness in
the network and offers an API to find which set of nodes provides a desired
graph.

## Design

![dia](https://github.com/stevejarvis/orbit-mapper/blob/master/docs/flow.png)

This mapping tool operates separately of the actual experiment. Once the
experiment has completed setup (and initialized the wireless interfaces), the
mapper will start to build a view of the network, after which time the
experiment script can query the offered API with a desired topology and receive
back the list of nodes that provide such a topology.

For example, the query

    GET http://console.grid.orbit-lab.org:4567/topology?2-1-1

might return

    192.168.0.8, 192.168.0.4, 192.168.0.12, 192.168.0.14

which would be a topology where the 192.168.0.8, 192.168.0.4, and 192.168.0.12
nodes are fully connected. The 192.168.0.12 and 192.168.0.14 nodes are
connected, but 192.168.0.14 cannot reach 192.168.0.8.

Further, the tool is designed to run with as little setup as possible (no
special image or distinct experiment) so that it integrates easily with existing
experiments. This does require proper choice of interfaces to go over. Part of
the mapper initialization will be to alter iptables to update the server process
over the wired connections.

## Implementation

Orbit mapper is written in Ruby, since that is the tool of choice for other
tooling.
