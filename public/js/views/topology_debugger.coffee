vis = require 'vis'
request = require 'browser-request'

require '../../css/views/topology_debugger.less'

View = Backbone.View.extend
  template: require '../../html/views/topology_debugger.jade'
  
  initialize: (options) ->
    {@name} = options



  render: ->
    @$el.html @template()

    opts =
      uri: "api/topologies/#{@name}"
      json: true
      method: 'GET'

    request opts, (err, res, body) =>
      console.log "GOT TOPOLOGY", body
      @topology = body
      @$el.html @template()

      nodes = []
      streams = []

      for bolt in @topology.bolts
        nodes.push
          id: bolt.id
          value: 1
          label: bolt.id

      for spout in @topology.spouts
        nodes.push
          id: spout.id
          value: 1
          # color: 'red'
          label: spout.id
          shape: 'triangle'

      for stream in @topology.streams
        streams.push
          from: stream.from
          to: stream.to
          value: 1
          title: stream.grouping.streamId

      container = @$('.graph-container').get(0)
      data =
        nodes: nodes
        edges: streams

      options = 
        nodes:
          shape: 'dot'
          scaling: label:
            min: 8
            max: 20
        edges: 
          arrows: 'to'

      console.log "FINAL DATA IS", data, options

      network = new (vis.Network)(container, data, options)

    @

module.exports = View