# StormChaser

![StormChaser](http://i.imgur.com/rZVXLgS.jpg)

### Status

Pre-alpha software, not for production use

# Getting started

## Installation

### Prequisites

- [node.js](https://nodejs.org/) installed locally
- An [Apache Storm](http://storm.apache.org/) topology you want to inspect/test/debug
- A local [ArangoDB](https://www.arangodb.com/) server on port 8529 (the default)

### Stormchaser App

`git clone git@github.com:bedrockdata/stormchaser.git`
`cd stormchaser`
`npm install`

### Debug bolt

The debug bolt is a middleman between your topology and stormchaser, and it's automatically inserted into your topology by the hooks if you're using streamparse. If you're not using streamparse, you should send the output of every bolt and every stream to the debug bolt.

The code for the bolt is [here](./bolts/debug.coffee)

## Usage

### First, start up the stormchaser app

`npm start`

This will cause the server to listen for incoming websocket connections from the debug bolt

### Setup Topology Graphs

Stormchaser needs information about the structure of your topology. Specifically, we need a JSON dump of Storm's "Flux dict".

If you're using [streamparse](https://github.com/Parsely/streamparse), we have a [simple topology hook](./streamparse/topology_hooks.py) to make things easier. Here's an example of how it's used:

```python
from streamparse import Topology
from stormchaser.path.topology_hooks import setup_debug_hooks

class MyTopologyClass(Topology)
  ... describe your spouts and bolts ...


# After the class is declared, the Topology parent class will 
# have built the final Flux dict, so we run our topology hooks
setup_debug_hooks(MyTopologyClass)
```

### Run storm topology

For Streamparse, running the storm topology will cause the topology python file to load, generating the graph json.

### Supervise your topology

When using the debug bolt any tuples sent through the topology will be automatically sent to Stormchaser. [Loading the UI](http://localhost:9821) will show you your topology graph
