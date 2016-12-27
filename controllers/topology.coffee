
class TopologyController

  constructor: (@manager) ->

  search: (req, res) =>
    @manager.search req.body, (results) ->
      res.json results

  delete: (req, res) =>
    topology = req.params.topology
    @manager.truncate topology, (results) ->
      res.json results

  upstream: (req, res) =>
    id = req.params.tupid
    topo = req.params.topology
    
    @manager.upstream id, topo, (results) ->
      res.json results

  getTopology: (req, res) =>
    name = req.params.name
    topology = @manager.loadTopology name
    res.json topology

  getTopologies: (req, res) =>
    @manager.loadTopologies (topologies) ->
      res.json topologies

  recordon: (req, res) =>
    console.log "RECORD ON"
    name = req.params.name
    @manager.setRecordMode name, true, ->
      res.json ok: true

  recordoff: (req, res) =>
    console.log "RECORD OFF"
    name = req.params.name
    @manager.setRecordMode name, false, ->
      res.json ok: true

module.exports = TopologyController