io = require 'socket.io-client'
uuid = require 'node-uuid'
loadDeps = require './deps'

loadDeps ->
  Router = require './router'
  window.stormchaser = {
    guid: uuid.v1()
    routers:
      main: new Router
    models: {}
    socket: io(window.location.origin)
  }

  stormchaser.socket.on 'connect', ->
    stormchaser.socket.emit 'identity',
      type: 'client'

  Backbone.history.start()