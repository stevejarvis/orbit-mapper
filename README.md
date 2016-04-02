# Orbit Mapper
![build status](https://api.travis-ci.org/stevejarvis/orbit-mapper.svg)
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

## Design

![dia](https://github.com/stevejarvis/orbit-mapper/blob/master/docs/flow.png)

This mapping tool operates separately of the actual experiment. Once the
experiment has completed setup (and initialized the wireless interfaces), the
mapper will start to build a view of the network, after which time the
experiment script can query the offered API with a desired topology and receive
back the list of nodes that provide such a topology.

For example, the query

    GET http://console.grid.orbit-lab.org:4567/topology?<TODO I don't know how this will work yet>

might return

    <some collection of node addresses or IDs>

Further, the tool is designed to run with as little setup as possible (no
special image or distinct experiment) so that it integrates easily with existing
experiments and Orbit images.

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
* puma
* sinatra
