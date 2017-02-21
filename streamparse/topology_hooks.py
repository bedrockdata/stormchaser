import os
import json

from streamparse import Topology, ShellBolt, Stream

def setup_debug_hooks(topo_class):
    inputs = []
    graph = topo_class.to_flux_dict('')
  
    for spec in topo_class.specs:
        for source_name, output in spec.outputs.items():
            if source_name == "error_handler_bolt":
                continue

            inputs.append(spec[source_name])
  
    topo_class.debug_bolt = ShellBolt.spec(command='coffee', script='node/bolts/debug.coffee',
                                           outputs=[Stream(fields=['config'])],
                                           inputs=inputs)
  
    topo_class.debug_bolt.name = "debug_bolt"
  
    Topology.add_bolt_spec(topo_class.debug_bolt, topo_class.thrift_bolts)
    topo_class.specs.append(topo_class.debug_bolt)
  
    directory = 'src/topology_graphs'

    if not os.path.exists(directory):
        os.makedirs(directory)

    topo_name = topo_class.__module__
    split_topo_name = topo_name.split('.')

    if len(split_topo_name) > 1:
        topo_name = split_topo_name[1]
    
    path = "{}/{}.json".format(directory, topo_name)
    fullpath = os.path.abspath(path)
  
    with open(fullpath, 'w+') as outfile:
        json.dump(graph, outfile, indent=2)
