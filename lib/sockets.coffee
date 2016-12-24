uuid = require 'node-uuid'
Socket = require 'socket.io'
bundle = require 'socket.io-bundle'
secrets = require '../config/secrets'

class Sockets
  constructor: (@server, @app, @session) ->
    @events = {}
    @clients = {}
    @subscribers = []

  setup: (app) ->
    @io = Socket.listen @server
    @io.on 'connection', @onConnection
    @io.use (socket, next) =>
      @session socket.request, {}, next

  subscribe: (callback) ->
    @subscribers.push callback

  on: (eventName, callback) ->
    @events[eventName] = callback
    for guid, socket of @clients
      socket.on eventName, (data) ->
        callback guid, data

  emit: (guid, name, data) =>
    # console.log "EMITTING", guid, name, data
    unless @clients[guid] is undefined
      @clients[guid].socket.emit name, data

  identifySocket: (socket, callback) ->
    socket.emit 'identity request'
    socket.on 'identity', (data) ->
      callback data

  onConnection: (socket) =>
    @identifySocket socket, (identity) =>
      guid = uuid.v1()
      
      client =
        identity: identity
        socket: socket

      @clients[guid] = client
      
      for eventName, callback of @events
        socket.on eventName, (data) ->
          callback guid, data

      socket.on 'disconnect', =>
        delete @clients[guid]

      for subCallback in @subscribers
        subCallback guid, client

module.exports = Sockets