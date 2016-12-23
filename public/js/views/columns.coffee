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
          <p>#{(@model.get('events') || []).length}</p>
        """
        @$el.css 'text-align', 'left'
        @delegateEvents()
        return @
  }
]