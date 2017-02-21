fs = require 'fs'
db = require('arangojs')()
storm = require 'storm-multilang-js'
Socket = require 'socket.io-client'
nodePath = require 'path'

class DebugBolt extends storm.BasicBolt

  initialize: (@conf, @context, done) ->
    done()
    @socket = Socket 'http://localhost:9821'
    
    @socket.on 'connect', () =>

    @socket.on 'identity request', () =>
      @loadGraphs (graphs) =>
        name = @conf['topology.name']

        if name.split('.')[0] is 'topologies'
          name = name.split('.').splice(1, 2).join('.')

        @socket.emit 'identity',
          type: 'debug bolt'
          graphs: graphs
          config: @conf
          context: @context
          topology: name

  loadGraphs: (callback) ->
    graphdir = nodePath.resolve __dirname, "../../topology_graphs"
    fs.readdir graphdir, (err, files) =>
      graphs = {}
      
      for file in files
        name = nodePath.basename file, '.json'  
        graph = require "#{graphdir}/#{file}"
        
        graphs[name] = graph

      callback graphs

  writeGraphs: (callback) ->
    if @hasWrittenGraphs
      return callback()
    else
      @hasWrittenGraphs = true

    @log "WRITE GRAPHS"
    graphdir = nodePath.resolve __dirname, "../../topology_graphs"

    @loadGraphs (graphs) =>
      @socket.emit 'graphs', graphs

      callback()

  process: (tup, done) ->
    @writeGraphs =>
      name = @conf['topology.name']

      if name.split('.')[0] is 'topologies'
        name = name.split('.').splice(1, 2).join('.')

      graph = require nodePath.resolve __dirname, "../../topology_graphs/#{name}"

      @socket.emit 'tup',
        tup: tup
        topology: name

      done()

bolt = new DebugBolt
bolt.run()