class GlobalParametersView extends Backbone.View

  events: {
    'change #input_mId' : 'setId'
    'change #input_apiToken' : 'setToken'
  }

  initialize: ->
    $('small#autofill-display')

  render: ->
    $(@el).html(Handlebars.templates.global_parameters())
    @

  setId: (ev) ->
    $('[name="mId"]').val($(ev.currentTarget).val()).trigger("change")
    $('#autofill-display').show().delay(1000).fadeOut(400)

  setToken: (ev) ->
    key = $(ev.currentTarget).val()
    if (key && key.trim() != "")
      window.authorizations.add("key", new ApiKeyAuthorization("Authorization","Bearer " + key, "header"))


    # $('#mId_selector').submit(function() {return false});
    # $('#api_selector').submit(function() {return false});
