vis = require 'vis'
extend = require 'extend'
request = require 'browser-request'
getSchema = require './schema'

require '../../css/views/topology_debugger.less'

View = Backbone.View.extend
  template: require '../../html/views/topology_debugger.jade'
  inspectNodeTemplate: require '../../html/views/node_inspect.jade'
  
  events:
    'click .search-button': 'searchClicked'
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

      selected = @nodes.get()[0].id

      @network.selectNodes [selected]
      @inspectNode selected

    @

  searchClicked: (event) ->
    event.preventDefault()

    val = @editor.getValue()
    console.log "SEARCHING WITH", val

    opts =
      uri: "api/tups/search"
      json: true
      method: 'POST'
      body: val

    request opts, (err, res, body) =>
      console.log "GOT RESPONSE", err, body
      @$('.search-results').JSONView body, {collapsed: true}
      @$('.search-results').JSONView 'expand', 1

  handleTotals: (totals) ->
    @totals = totals

    for model in @collection.models
      name = model.get 'id'
      
      if totals.nodes[name]
        model.set 'value', totals.nodes[name]

    @table.render()
    @updateTopoGraph()
    @updateTotalsDisplay()

  updateTotalsDisplay: ->
    @$('.total-display').text "#{@totals.total} events captured"

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

    val = @editor.getValue()
    val = extend val,
      source: id
    @editor.setValue val

    @$('.node-inspect-container').html @inspectNodeTemplate(context)

  setupControls: ->
    @collection = new Backbone.Collection @nodes.get()
    window.collection = @collection
    window.table = @table = new Backgrid.Grid
      columns: require './columns'
      collection: @collection

    @$('.results-table-container').html @table.render().el

    nodeNames = []
    for node in @nodes.get()
      nodeNames.push node.id

    @editor = window.editor = new JSONEditor @$('.search-controls').get(0),
      theme: 'bootstrap3'
      schema: getSchema nodeNames
      iconlib: "fontawesome4"
      disable_collapse: true
      disable_edit_json: true
      keep_oneof_values: false
      disable_properties: true
      no_additional_properties: true

  getNetworkData: ->
    nodes = new vis.DataSet
    streams = new vis.DataSet

    for bolt in @topology.bolts
      total = @totals?.nodes[bolt.id] || 0
      nodes.add
        id: bolt.id
        type: 'bolt'
        value: total
        label: bolt.id
        title: "#{bolt.id} - #{total} tups"

    for spout in @topology.spouts
      total = @totals?.nodes[spout.id] || 0
      nodes.add
        id: spout.id
        type: 'spout'
        value: total
        label: spout.id
        title: "#{spout.id} - #{total} tups"
        shape: 'triangle'

    for stream in @topology.streams
      streams.add
        from: stream.from
        to: stream.to
        value: 1
        title: stream.grouping.streamId

    {streams: streams, nodes: nodes}

  updateTopoGraph: ->
    for name, total of @totals.nodes
      @network.nodesHandler.body.data.nodes.update [
        {
          id: name
          value: total
          title: "#{name} - #{total} captured"
        }
      ]

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