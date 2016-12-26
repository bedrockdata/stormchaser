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
          else
            @calculateTotals name, config, (totals) ->
              config.totals = totals
              client.emit 'totals', config.totals
    , 2000

  setSockets: (@sockets) ->
    @sockets.subscribe @onConnection

    @sockets.on 'tup', (guid, data) =>
      topology = @identities[guid].topology
      @handleTupData topology, data.tup, ->
        null

  search: (config, callback) ->
    console.log "SEARCHING WITH", config

    if config.value is ""
      query = """
        for tup in tups
          FILTER tup.component == "#{config.source}"
          LIMIT #{config.limit || 10}
          RETURN tup
      """

    else

      if config.path
        filter = """
          FILTER tup.values[#{config.index}].#{path} == #{config.value}
        """
      else
        filter = """
          FILTER tup.values[#{config.index}] == #{config.value}
        """

      query = """
        FOR tup IN tups
          #{filter}
          LIMIT #{config.limit || 10}
          RETURN tup
      """

    console.log "FINAL QUERY", query

    db.query query, (err, cursor) ->
      cursor.all (err, results) ->
        callback results

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

        fs.writeFileSync "#{dirname}/#{name}.json", JSON.stringify(graph, null, 2)

    else
      @clients[guid] = socket

  calculateTotals: (name, config, callback) ->
    query = """
      for tup in tups
        COLLECT component = tup.component WITH COUNT INTO total
        return {component, total}
    """

    db.query query, (err, cursor) =>
      cursor.all (err, results) =>
        total = 0
        nodes = {}
        for result in results
          total += result.total
          nodes[result.component] = result.total

        totals =
          total: total
          nodes: nodes

        callback totals

  handleTupData: (topology, tup, callback) =>
    config = @topologies[topology]

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
        callback()

  setRecordMode: (name, shouldRecord, callback) ->
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