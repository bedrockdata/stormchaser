fs = require 'fs'
nodePath = require 'path'

class TopologyManager

  constructor: () ->
    @topologies = {}

  setSockets: (@sockets) ->
    @sockets.subscribe @onConnection

    @sockets.on 'tup', (guid, data) ->
      console.log "GOT TUP DATA", guid, data

  onConnection: (guid, client) ->
    {socket, identity} = client    
    {type, graphs} = identity

    if type isnt 'debug bolt'
      return

    dirname = nodePath.resolve __dirname, '../graphs'
    if not fs.existsSync(dirname)
      fs.mkdirSync dirname

    for name, graph of graphs
      fs.writeFileSync "#{dirname}/#{name}.json", JSON.stringify(graph, null, 2)

  loadTopology: (name, callback) ->
    dirname = nodePath.resolve __dirname, '../graphs'
    graph = require "#{dirname}/#{name}.json"
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