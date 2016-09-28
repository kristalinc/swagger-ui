class GlobalParametersView extends Backbone.View

  events: {
    'change #input_mId'       : 'setId'
    'change #input_apiToken'  : 'setToken'
    'focusin'                 : 'hasFocus'
    'focusout'                : 'lostFocus'
    'input .c-input-field'    : 'checkForContent'
  }

  initialize: ->
    $('small#autofill-display')

  render: ->
    $(@el).html(Handlebars.templates.global_parameters())
    @

  hasFocus: ->
    form = $('.c-box-filter', $(@el))
    form.find('input:focus').parent().addClass "c-input-active"

  lostFocus: ->
    form = $('.c-box-filter', $(@el))
    form.find('input').parent().removeClass "c-input-active"

  checkForContent: (e) ->
    inputField = $(e.currentTarget)
    if ($(inputField).length && $(inputField).val().length)
      $(inputField).parent('.input-group').addClass('c-input-group-filled')
    else
      $(inputField).parent('.input-group').removeClass('c-input-group-filled')

  setId: (ev) ->
    $('[name="mId"]').val($(ev.currentTarget).val()).trigger("change")
    $('#autofill-display').show().delay(1000).fadeOut(400)

  setToken: (ev) ->
    key = $(ev.currentTarget).val()
    if (key && key.trim() != "")
      window.authorizations.add("key", new ApiKeyAuthorization("Authorization","Bearer " + key, "header"))


    # $('#mId_selector').submit(function() {return false});
    # $('#api_selector').submit(function() {return false});
