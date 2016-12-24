fs = require 'fs'
db = require('arangojs')()
nodePath = require 'path'

class TopologyManager

  constructor: () ->
    @clients = {}
    @topologies = {}
    @identities = {}

    db.useDatabase 'stormchaser'

    setInterval () =>
      for name, config of @topologies
        for guid, client of @clients
          if config.totals
            client.emit 'totals', config.totals
    , 2000

  setSockets: (@sockets) ->
    @sockets.subscribe @onConnection

    @sockets.on 'tup', (guid, data) =>
      topology = @identities[guid].topology
      @handleTupData topology, data.tup

  onConnection: (guid, client) =>
    {socket, identity} = client    
    {type, graphs} = identity

    if type is 'debug bolt'
      @identities[guid] = identity

      dirname = nodePath.resolve __dirname, '../graphs'
      if not fs.existsSync(dirname)
        fs.mkdirSync dirname

      for name, graph of graphs
        if @topologies[name]
          @topologies[name].graph = graph
        else
          @topologies[name] =
            graph: graph
            record: false
            totals:
              total: 0
              nodes: {}

        fs.writeFileSync "#{dirname}/#{name}.json", JSON.stringify(graph, null, 2)

    else
      @clients[guid] = socket

  handleTupData: (topology, tup) =>
    config = @topologies[topology]

    name = tup.component
    config.totals.total += 1
    if config.totals.nodes[name] is undefined
      config.totals.nodes[name] = 0
    config.totals.nodes[name] += 1

    if not config.record
      console.log "PASSING THROUGH TUP", topology, tup.id
    else
      console.log "RECORDING TUP", topology, tup.id
      
      tup._key = tup.id

      tupQuery = """
        UPSERT {_key: "#{tup.id}"}
        INSERT #{JSON.stringify(tup)}
        UPDATE #{JSON.stringify(tup)} in tups
      """

      db.query tupQuery, (err, cursor) =>


  setRecordMode: (name, shouldRecord) ->
    console.log "SET RECORD", name, shouldRecord

    # Clear totals if we're just now engaging record
    if not @topologies[name].record and shouldRecord
      @topologies[name].totals =
        total: 0
        nodes: {}

    @topologies[name].record = shouldRecord

  loadTopology: (name, callback) ->
    dirname = nodePath.resolve __dirname, '../graphs'
    graph = require "#{dirname}/#{name}.json"

    if @topologies[name]
      @topologies[name].graph = graph
    else
      @topologies[name] =
        graph: graph
        record: false
        totals:
          total: 0
          nodes: {}

    callback graph

  loadTopologies: (callback) ->
    dirname = nodePath.resolve __dirname, '../graphs'
    fs.readdir dirname, (err, files) ->
      
      graphs = {}
      for file in files
        name = nodePath.basename file, '.json'
        graphs[name] = require "#{dirname}/#{file}"

      callback graphs

module.exports = TopologyManager