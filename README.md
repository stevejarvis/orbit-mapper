# Orbit Mapper
[![build status](https://api.travis-ci.org/stevejarvis/orbit-mapper.svg)](https://travis-ci.org/stevejarvis/orbit-mapper)
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

It is a goal of this tool to be as unobtrusive in experiments as possible.
This includes adding minimal wireless traffic and requiring minimal
changes to any existing OMF experiment description. This means, for example,
interactions between the nodes and controller happen only over ethernet and
no additional OML measurements need to be made.

## Getting Started
See the [tutorial on the wiki](https://github.com/stevejarvis/orbit-mapper/wiki/Tutorial) for complete startup instructions in Orbit Lab.

## Design

![dia](https://github.com/stevejarvis/orbit-mapper/blob/master/doc/flow.png)

This mapping tool operates separately of the actual experiment. Once the
experiment has completed setup (and initialized the wireless interfaces), the
mapper will start to build a view of the network, after which time the
experiment script can query the offered API with a node identifier and receive
information on the connectivity of that node.

For example, the query

    GET http://console.grid.orbit-lab.org:4567/node1-2

might return

    [
      {"success":80,"rtt":1.024,"address":"192.168.0.1","host":"node1-1"},
      {"success":60,"rtt":1.358,"address":"192.168.0.3","host":"node1-3"},
      {"success":100,"rtt":1.709,"address":"192.168.0.4","host":"node1-4"},
      {"success":100,"rtt":0.885,"address":"192.168.0.5","host":"node2-1"},
      {"success":80,"rtt":1.59,"address":"192.168.0.6","host":"node-2"}
    ]

Indicating the connection information to each of those particular nodes, from
the context of node1-2.

Further, the tool is designed to run with as little setup as possible (no
special image or distinct experiment) so that it integrates relatively easily
with existing experiments and Orbit images.

## Implementation

Orbit mapper is written in Ruby, since that is the tool of choice for other
Orbit tooling.

### Required Gems

The console machine doesn't have all required gems available, nor does it have
Internet access, so dependencies are included in deps/ and must be installed
manually, e.g.:

    gem install --user-install net-ssh-2.6.5.gem

* net-ssh
* net-scp
* builder
* sinatra
