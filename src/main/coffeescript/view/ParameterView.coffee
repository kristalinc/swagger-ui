class ParameterView extends Backbone.View

  events: {
    'change .param-value': 'valueChanged'
  }

  initialize: ->
    @choices = @model.get("choices")
    @listenTo(@choices, "expansionFromJSON", @expansionFromJSON)
    if @model.get("isFilter")
      @listenTo(@choices, "change", @updateChoices);


    Handlebars.registerHelper 'isArray',
      (param, opts) ->
        if param.type.toLowerCase() == 'array' || param.allowMultiple
          opts.fn(@)
        else
          opts.inverse(@)

  render: ->
    template = @template()
    $(@el).html(template(@model.toJSON()))

    @addDataType()
    @addParameterContentTypeView()

    # render each choice

    if @model.get("isFilter")
      @addChoiceView()
    @

  # Return an appropriate template based on if the parameter is a list, readonly, required
  template: ->
    if @model.get("isFilter")
      Handlebars.templates.param_complex_query
    else
      if @model.get("isExpand")
        Handlebars.templates.param_simple_query
      else
        if @model.get("isList")
          Handlebars.templates.param_list
        else
          if @model.get("required")
            Handlebars.templates.param_required
          else
            Handlebars.templates.param


  addDataType: ->
    if !@model.get("isBody")
      $('.data-type', $(@el)).html(@model.get("type"))

  addParameterContentTypeView: ->
    isParam = false

    if @model.get("isBody")
      isParam = true

    contentTypeModel =
      isParam: isParam

    if isParam
      parameterContentTypeView = new ParameterContentTypeView({model: contentTypeModel})
      $('.parameter-content-type', $(@el)).append(parameterContentTypeView.render().el)
    else
      responseContentTypeView = new ResponseContentTypeView({model: contentTypeModel})
      $('.response-content-type', $(@el)).append(responseContentTypeView.render().el)

  addChoiceView: (currentValue) ->
    # Render a query choice
    choiceView = new ParameterChoiceView({model: @choices, currentValue: currentValue})
    if currentValue
      $('.query-choices div:last-child', $(@el)).before(choiceView.render().el)
    else
      $('.query-choices', $(@el)).append choiceView.render().el

  updateChoices: ->
    $('input.parameter', $(@el)).val(@choices.get("queryParamString"))
    unless $('.close', $(@el)).last().prop('disabled')
      @addChoiceView()

  removeChoiceView: (viewId) ->
    view = @choiceViews[viewId]
    view.remove()
    delete @choiceViews[viewId]
    @choiceSet()

  refreshChoiceViews: ->
    for viewId in Object.keys(@choiceViews)
      @choiceViews[viewId].render()

  expansionFromJSON: (field) ->
    $select = $('.param-value', $(@el))
    value = $select.val()
    value = [] unless value
    value.push(field)
    $('.param-value', $(@el)).val(value).trigger("change")

  valueChanged: (ev) ->
    value = $(ev.currentTarget).val()
    @model.setValue(value)
