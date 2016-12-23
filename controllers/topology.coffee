
class TopologyController

  constructor: (@manager) ->

  getTopology: (req, res) =>
    name = req.params.name
    @manager.loadTopology name, (topology) ->
      res.json topology

  getTopologies: (req, res) =>
    @manager.loadTopologies (topologies) ->
      res.json topologies

module.exports = TopologyController