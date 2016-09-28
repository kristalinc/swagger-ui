class OperationView extends Backbone.View
  invocationUrl: null

  events: {
    'submit .sandbox'         : 'submitOperation'
    'click .submit'           : 'submitOperation'
    'click .response_hider'   : 'hideResponse'
    'click .toggleOperation'  : 'toggleOperationContent'
    'click .expandable'       : 'expandedFromJSON'
    'focusin .c-input-field'  : 'hasFocus'
    'focusout .c-input-field' : 'lostFocus'
    'focusin .param-code'     : 'hasQueryFocus'
    'focusout .param-code'    : 'lostQueryFocus'
    'input .c-input-field'    : 'checkForContent'
    'change .c-input-field'   : 'checkForContent'
  }

  initialize: ->

  template: ->
    Handlebars.templates.operation

  render: ->
    template = @template()
    $(@el).html(template(@model.toJSON()))

    contentTypeModel =
      isParam: false

    responseContentTypeView = new ResponseContentTypeView({model: contentTypeModel})
    $('.response-content-type', $(@el)).append responseContentTypeView.render().el

    @addParameterViews()

    @addSignatureView()

    # Render each response code
    @addStatusCode statusCode for statusCode in @model.get("responseMessages")

    @

  hasFocus: ->
    form = $('.sandbox', $(@el))
    form.find('input:focus').parent().addClass "c-input-active"
    form.find('textarea:focus').parent().addClass "c-input-active"

  hasQueryFocus: (e) ->
    queryCode = $(e.currentTarget)
    queryCode.addClass "c-query-active"

  lostFocus: ->
    form = $('.sandbox', $(@el))
    form.find('input').parent().removeClass "c-input-active"
    form.find('textarea').parent().removeClass "c-input-active"

  lostQueryFocus: ->
    queryCode = $('.param-code', $(@el))
    queryCode.removeClass "c-query-active"

  checkForContent: (e) ->
    inputField = $(e.currentTarget)
    if ($(inputField).length && $(inputField).val().length)
      $(inputField).parent('.c-input-group').addClass('c-input-group-filled')
    else
      $(inputField).parent('.c-input-group').removeClass('c-input-group-filled')

  addSignatureView: ->
    signatureModel = @model.getSignatureModel()
    if signatureModel
      signatureView = new SignatureView({model: signatureModel})
      $('.model-signature', $(@el)).append(signatureView.render().el)
    else
      $('.data-type', $(@el)).html(@model.get("type"))

  addParameterViews: ->
    for param in @model.get("parameterModels")
      paramView = new ParameterView({model: param, tagName: 'div'})
      $('.operation-params', $(@el)).append paramView.render().el
      signatureModel = param.getSignatureModel()
      if signatureModel and param.get("isBody")
        signatureView = new SignatureView({model: signatureModel})
        $('.model-signature', $(@el)).append(signatureView.render().el)


  addStatusCode: (statusCode) ->
    # Render status codes
    statusCodeView = new StatusCodeView({model: statusCode, tagName: 'tr'})
    $('.operation-status', $(@el)).append statusCodeView.render().el

  submitOperation: (ev) ->
    ev?.preventDefault()

    # Check for errors
    form = $('.sandbox', $(@el))
    error_free = true
    form.find("input.required").each ->
      $(@).parent().removeClass "error"
      if jQuery.trim($(@).val()) is ""
        $(@).parent().addClass "error"
          callback: => $(@).focus()
        error_free = false

    # if error free submit it
    if error_free
      map = {}
      opts = {parent: @}
      isFileUpload = false
      for param in @model.get("parameterModels")
        if param.get("isFile")
          isFileUpload = true
        value = param.getQueryParamString()
        if value && jQuery.trim(value).length > 0
          map[param.get("name")] = value

      opts.responseContentType = $("div select[name=responseContentType]", $(@el)).val()
      opts.requestContentType = $("div select[name=parameterContentType]", $(@el)).val()

      $(".response_throbber", $(@el)).show()
      if isFileUpload
        @handleFileUpload map, form
      else
        @model.do(map, opts, @showCompleteStatus, @showErrorStatus, @)

  success: (response, parent) ->
    parent.showCompleteStatus response

  handleFileUpload: (map, form) ->
    for o in form.serializeArray()
      if(o.value? && jQuery.trim(o.value).length > 0)
        map[o.name] = o.value

    # requires HTML5 compatible browser
    bodyParam = new FormData()
    params = 0

    # add params
    for param in @model.get("parameters")
      if param.paramType is 'form'
        if map[param.name] != undefined
            bodyParam.append(param.name, map[param.name])

    # headers in operation
    headerParams = {}
    for param in @model.get("parameters")
      if param.paramType is 'header'
        headerParams[param.name] = map[param.name]

    log headerParams

    # add files
    for el in form.find('input[type~="file"]')
      if typeof el.files[0] isnt 'undefined'
        bodyParam.append($(el).attr('name'), el.files[0])
        params += 1

    log(bodyParam)

    @invocationUrl =
      if @model.supportHeaderParams()
        headerParams = @model.getHeaderParams(map)
        @model.urlify(map, false)
      else
        @model.urlify(map, true)

    $(".request_url", $(@el)).html "<pre>" + @invocationUrl + "</pre>"

    obj =
      type: @model.get("method")
      url: @invocationUrl
      headers: headerParams
      data: bodyParam
      dataType: 'json'
      contentType: false
      processData: false
      error: (data, textStatus, error) =>
        @showErrorStatus(@wrap(data), @)
      success: (data) =>
        @showResponse(data, @)
      complete: (data) =>
        @showCompleteStatus(@wrap(data), @)

    # apply authorizations
    if window.authorizations
      window.authorizations.apply obj

    if params is 0
      obj.data.append("fake", "true");

    jQuery.ajax(obj)
    false
    # end of file-upload nastiness

  # wraps a jquery response as a shred response

  wrap: (data) ->
    headers = {}
    headerArray = data.getAllResponseHeaders().split("\r")
    for i in headerArray
      h = i.split(':')
      if (h[0] != undefined && h[1] != undefined)
        headers[h[0].trim()] = h[1].trim()

    o = {}
    o.content = {}
    o.content.data = data.responseText
    o.headers = headers
    o.request = {}
    o.request.url = @invocationUrl
    o.status = data.status
    o

  # handler for hide response link
  hideResponse: (e) ->
    e?.preventDefault()
    $(".response", $(@el)).slideUp(200)
    $(".response_hider", $(@el)).fadeOut(200)


  # Show response from server
  showResponse: (response) ->
    prettyJson = JSON.stringify(response, null, "\t").replace(/\n/g, "<br>")
    $(".response_body", $(@el)).html escape(prettyJson)

  # Show error from server
  showErrorStatus: (data, parent) ->
    parent.showStatus data

  # show the status codes
  showCompleteStatus: (data, parent) ->
    parent.showStatus data

  # Adapted from http://stackoverflow.com/a/2893259/454004
  formatXml: (xml) ->
    reg = /(>)(<)(\/*)/g
    wsexp = /[ ]*(.*)[ ]+\n/g
    contexp = /(<.+>)(.+\n)/g
    xml = xml.replace(reg, '$1\n$2$3').replace(wsexp, '$1\n').replace(contexp, '$1\n$2')
    pad = 0
    formatted = ''
    lines = xml.split('\n')
    indent = 0
    lastType = 'other'
    # 4 types of tags - single, closing, opening, other (text, doctype, comment) - 4*4 = 16 transitions
    transitions =
      'single->single': 0
      'single->closing': -1
      'single->opening': 0
      'single->other': 0
      'closing->single': 0
      'closing->closing': -1
      'closing->opening': 0
      'closing->other': 0
      'opening->single': 1
      'opening->closing': 0
      'opening->opening': 1
      'opening->other': 1
      'other->single': 0
      'other->closing': -1
      'other->opening': 0
      'other->other': 0

    for ln in lines
      do (ln) ->

        types =
          # is this line a single tag? ex. <br />
          single: Boolean(ln.match(/<.+\/>/))
          # is this a closing tag? ex. </a>
          closing: Boolean(ln.match(/<\/.+>/))
          # is this even a tag (that's not <!something>)
          opening: Boolean(ln.match(/<[^!?].*>/))

        [type] = (key for key, value of types when value)
        type = if type is undefined then 'other' else type

        fromTo = lastType + '->' + type
        lastType = type
        padding = ''

        indent += transitions[fromTo]
        padding = ('  ' for j in [0...(indent)]).join('')
        if fromTo == 'opening->closing'
          #substr removes line break (\n) from prev loop
          formatted = formatted.substr(0, formatted.length - 1) + ln + '\n'
        else
          formatted += padding + ln + '\n'

    formatted


  # puts the response data in UI
  showStatus: (response) ->
    if response.content is undefined
      content = response.data
      url = response.url
    else
      content = response.content.data
      url = response.request.url
    headers = response.headers

    # if server is nice, and sends content-type back, we can use it
    contentType = if headers && headers["Content-Type"] then headers["Content-Type"].split(";")[0].trim() else null

    if !content
      code = $('<code />').text("no content")
      pre = $('<pre class="json" />').append(code)
    else if contentType is "application/json" || /\+json$/.test(contentType)
      code = $('<code />').text(JSON.stringify(JSON.parse(content), null, "  "))
      pre = $('<pre class="json" />').append(code)
    else if contentType is "application/xml" || /\+xml$/.test(contentType)
      code = $('<code />').text(@formatXml(content))
      pre = $('<pre class="xml" />').append(code)
    else if contentType is "text/html"
      code = $('<code />').html(content)
      pre = $('<pre class="xml" />').append(code)
    else if /^image\//.test(contentType)
      pre = $('<img>').attr('src',url)
    else
      # don't know what to render!
      code = $('<code />').text(content)
      pre = $('<pre class="json" />').append(code)

    response_body = pre
    $(".request_url", $(@el)).html "<pre>" + decodeURIComponent(url) + "</pre>"
    $(".response_code", $(@el)).html "<pre>" + response.status + "</pre>"
    $(".response_body", $(@el)).html response_body
    $(".response_headers", $(@el)).html "<pre>" + JSON.stringify(response.headers, null, "  ").replace(/\n/g, "<br>") + "</pre>"
    $(".response", $(@el)).slideDown(200)
    $(".response_hider", $(@el)).show()
    $(".response_throbber", $(@el)).hide()
    hljs.highlightBlock($('.response_body', $(@el))[0])

  toggleOperationContent: ->
    $elem = $('#' + swaggerUiRouter.escapeResourceName(@model.get("parentId")) + "_" + @model.get("nickname") + "_content")
    if $elem.is(':visible')
      $elem.parent('.operation').removeClass('expanded')
      $elem.prev('.heading').find('.operation-actions i').removeClass()
      $elem.prev('.heading').find('.operation-actions i').addClass('fa fa-angle-down')
      $elem.slideUp(200)
    else
      $elem.parent('.operation').addClass('expanded')
      $elem.prev('.heading').find('.operation-actions i').removeClass()
      $elem.prev('.heading').find('.operation-actions i').addClass('fa fa-angle-up')
      $elem.slideDown(200)

    # if $elem.isnot(':visible') then $($elem).parent.addClass('content-open') else $($elem).parent.removeClass('content-open')
