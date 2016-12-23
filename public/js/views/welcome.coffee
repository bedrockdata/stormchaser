require '../../css/views/welcome.less'

request = require 'browser-request'

WelcomeView = Backbone.View.extend
  template: require '../../html/views/welcome.jade'
  
  render: ->
    opts =
      uri: 'api/topologies'
      json: true
      method: 'GET'

    request opts, (err, res, body) =>
      console.log "GOT TOPOLOGIES", body
      @topologies = body
      @$el.html @template()

    @

module.exports = WelcomeView