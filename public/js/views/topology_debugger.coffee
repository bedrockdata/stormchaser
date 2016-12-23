vis = require 'vis'
request = require 'browser-request'

require '../../css/views/topology_debugger.less'

View = Backbone.View.extend
  template: require '../../html/views/topology_debugger.jade'
  inspectNodeTemplate: require '../../html/views/node_inspect.jade'
  
  events:
    'click .inspect-bolt-link': 'inspectLinkClicked'

  initialize: (options) ->
    {@name} = options

  render: ->
    opts =
      uri: "api/topologies/#{@name}"
      json: true
      method: 'GET'

    request opts, (err, res, body) =>
      console.log "GOT TOPOLOGY", body
      @topology = body
      @$el.html @template()
      @setupTopoGraph()
      @setupControls()

      @network.selectNodes [@nodes[0].id]
      @inspectNode @nodes[0].id

    @

  inspectLinkClicked: (event) ->
    event.preventDefault()
    console.log "CLICK FROM", $(event.target).text()
    @inspectNode $(event.target).text()

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
    collection = new Backbone.Collection @nodes

    @table = new Backgrid.Grid
      columns: require './columns'
      collection: collection

    @$('.results-table-container').html @table.render().el

  setupTopoGraph: ->
    nodes = []
    streams = []

    for bolt in @topology.bolts
      nodes.push
        id: bolt.id
        type: 'bolt'
        value: 1
        label: bolt.id

    for spout in @topology.spouts
      nodes.push
        id: spout.id
        type: 'spout'
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

    @nodes = nodes
    @network = new vis.Network container, data, options

    @network.on 'click', (event) =>
      @inspectNode event.nodes[0]

module.exports = View