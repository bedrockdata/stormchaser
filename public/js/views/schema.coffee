module.exports = (nodes) ->
  search:
    type: 'object'
    title: 'Search'
    format: 'grid'
    properties:
      source:
        description: 'Source node (bolt or spout)'
        type: 'string'
        enum: nodes
      stream:
        description: 'Source node (bolt or spout)'
        type: 'string'
        default: 'default'
      index:
        description: 'tup arg index'
        type: 'number'
      path:
        description: 'Field path using javascript.dot.notation (blank for top level)'
        type: 'string'
      value:
        description: 'Value to look for (blank for any)'
        type: 'string'
      limit:
        description: 'Max number of documents to return'
        default: 10
        type: 'number'
  upstream:
    type: 'object'
    title: 'Get Upstream Data'
    format: 'grid'
    properties:
      id:
        description: 'tuple id'
        type: 'string'
        