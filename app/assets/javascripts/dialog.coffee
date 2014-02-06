AWSSC = window.AWSSC = window.AWSSC ? {}

AWSSC.ModalDialog = ->
  self = {}
  self.show = (opts) ->
    dialog = $("<div>").html(opts.body)
    $("body").append(dialog)
    dialog.dialog
      title: opts.title
      modal: true
      buttons:
        "OK": -> dialog.dialog("close")
      close: -> dialog.remove()
  return self

AWSSC.ModalPrompt = ->
  self = {}
  self.show = (opts) ->
    dfd = $.Deferred()
    dialog = $("<div>").html(opts.body).hide()
    textInput = $('<input type="text">').attr(size: opts.size || 30)
    textInput.val(opts.value) if opts.value
    textInput.on "keypress", (e) ->
      if e.keyCode == 13
        ok_button_pressed()
    ok_button_pressed = ->
      dfd.resolve(textInput.val())
      dialog.dialog("close")

    dialog.append($("<div>").append(textInput))
    if opts.extra
      dialog.append(opts.extra)
    $("body").append(dialog)
    dialog.dialog
      title: opts.title
      modal: true
      buttons:
        "OK": ok_button_pressed
        "Cancel": -> dialog.dialog("close")
      close: ->
        dialog.remove()
        dfd.reject(null)
    dfd.promise()
  return self
