TableUtils = require './shared/table_utils'

getUrl = (model) -> "javascript:void(0)"

module.exports = [
  TableUtils.indexCell()
  TableUtils.textLinkToSelf 'id', 'Name', getUrl, {align: 'left', class: 'inspect-bolt-link'}
  {
    editable: false
    sortable: false
    label: 'Type'
    cell: Backgrid.IntegerCell.extend
      render: ->
        @$el.empty()
        @$el.html """
          <p>#{@model.get('type')}</p>
        """
        @$el.css 'text-align', 'left'
        @delegateEvents()
        return @
  }
  {
    editable: false
    sortable: false
    label: 'Events Captured'
    cell: Backgrid.IntegerCell.extend
      render: ->
        @$el.empty()
        @$el.html """
          <p>#{@model.get('value')}</p>
        """
        @$el.css 'text-align', 'left'
        @delegateEvents()
        return @
  }
  {
    cell: Backgrid.IntegerCell.extend
      className: "string-cell sortable centered-string-cell"
      formatter: Backgrid.StringFormatter
      render: ->
        @$el.empty()

        data = @model.attributes
        if data.data isnt undefined and data.data.constructor is String
          try
            data.data = JSON.parse data.data
          catch err
            console.log "FAILED TO PARSE DATA", err                

        index = @model.collection.indexOf @model
        @$el.html """
          <button type="button" stepIndex="#{index}" class="btn btn-default view-data-button">
            Data
          </button>
        """

        @$('.view-data-button').on 'click', (event) =>
          event.preventDefault()

          dialog = vex.open
            contentCSS:
              width: 1200
            content: """
              <div class="container data-container"></div>
              <br>
              <a class="btn btn-lg btn-primary close-button">Close</a>
              <a class="btn btn-lg btn-primary copy-button">Copy to Clipboard</a>
            """
            afterOpen: (value) =>
              $('.close-button').on 'click', (event) => vex.close @dialog.data().vex.id
              $('.copy-button').on 'click', (event) => clipboard.copy JSON.stringify data, null, 2

              $('.data-container').JSONView data, {collapsed: true}
              $('.data-container').JSONView 'expand', 1

        return @
    name: 'data'
    label: 'Data'
    className: 'agent-name-cell'
    editable: false
    sortable: true
  }
]