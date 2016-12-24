vis = require 'vis'
request = require 'browser-request'

require '../../css/views/topology_debugger.less'

View = Backbone.View.extend
  template: require '../../html/views/topology_debugger.jade'
  inspectNodeTemplate: require '../../html/views/node_inspect.jade'
  
  events:
    'click .inspect-bolt-link': 'inspectLinkClicked'
    'click .record-stop-button': 'recordStopClicked'
    'click .record-start-button': 'recordStartClicked'

  initialize: (options) ->
    {@name} = options

    stormchaser.socket.on 'totals', (data) =>
      @handleTotals data

  render: ->
    opts =
      uri: "api/topologies/#{@name}"
      json: true
      method: 'GET'

    request opts, (err, res, body) =>
      console.log "GOT TOPOLOGY", body
      @topology = body
      @$el.html @template()
      @$('.record-stop-button').hide()

      @setupTopoGraph()
      @setupControls()

      @network.selectNodes [@nodes[0].id]
      @inspectNode @nodes[0].id

    @

  handleTotals: (totals) ->
    @totals = totals

    console.log "TOTALS", totals
    for model in @collection.models
      name = model.get 'id'
      
      if totals.nodes[name]
        model.set 'value', totals.nodes[name]

    @table.render()
    @updateTopoGraph()

  recordStopClicked: (event) ->
    event.preventDefault()

    opts =
      uri: "api/topologies/#{@name}/recordoff"
      method: 'POST'
      body: {}

    request opts, (err, res, body) =>
      @$('.record-stop-button').hide()
      @$('.record-start-button').show()

  recordStartClicked: (event) ->
    event.preventDefault()

    opts =
      uri: "api/topologies/#{@name}/recordon"
      method: 'POST'
      body: {}

    request opts, (err, res, body) =>
      @$('.record-stop-button').show()
      @$('.record-start-button').hide()

  inspectLinkClicked: (event) ->
    event.preventDefault()
    id = $(event.target).text()
    @network.selectNodes [id]    
    @inspectNode id

  getNodeDefs: (id) ->
    for bolt in @topology.bolts
      if bolt.id is id
        return bolt

    for spout in @topology.spouts
      if spout.id is id
        return spout

  inspectNode: (id) ->
    if id is undefined
      return

    context =
      id: id
      defs: @getNodeDefs(id)

    console.log "INSPECTING", context

    @$('.node-inspect-container').html @inspectNodeTemplate(context)

  setupControls: ->
    @collection = new Backbone.Collection @nodes
    window.collection = @collection
    window.table = @table = new Backgrid.Grid
      columns: require './columns'
      collection: @collection

    @$('.results-table-container').html @table.render().el

  getNetworkData: ->
    nodes = []
    streams = []

    for bolt in @topology.bolts
      total = @totals?.nodes[bolt.id] || 0
      nodes.push
        id: bolt.id
        type: 'bolt'
        value: total
        label: bolt.id
        title: "#{bolt.id} - #{total} captured"

    for spout in @topology.spouts
      total = @totals?.nodes[bolt.id] || 0
      nodes.push
        id: spout.id
        type: 'spout'
        value: total
        label: spout.id
        title: "#{spout.id} - #{total} captured"
        shape: 'triangle'

    for stream in @topology.streams
      streams.push
        from: stream.from
        to: stream.to
        value: 1
        title: stream.grouping.streamId

    {streams: streams, nodes: nodes}

  updateTopoGraph: ->
    {nodes, streams} = @getNetworkData()

    @network.setData
      nodes: nodes
      edges: streams

  setupTopoGraph: ->
    {nodes, streams} = @getNetworkData()

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

    @nodes = nodes
    @network = new vis.Network container, data, options
    window.network = @network
    @network.on 'click', (event) =>
      @inspectNode event.nodes[0]

module.exports = View