
class TopologyController

  constructor: (@manager) ->

  getTopology: (req, res) =>
    name = req.params.name
    @manager.loadTopology name, (topology) ->
      res.json topology

  getTopologies: (req, res) =>
    @manager.loadTopologies (topologies) ->
      res.json topologies

  recordon: (req, res) =>
    console.log "RECORD ON"
    name = req.params.name
    @manager.setRecordMode name, true
    res.json ok: true

  recordoff: (req, res) =>
    console.log "RECORD OFF"
    name = req.params.name
    @manager.setRecordMode name, false
    res.json ok: true

module.exports = TopologyController