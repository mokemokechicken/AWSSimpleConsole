AWSSC = AWSSC ? {}
window.AWSSC = AWSSC

$.wait = (duration) ->
  dfd = $.Deferred()
  setTimeout( ->
    dfd.resolve()
  , duration)
  return dfd

AWSSC.EC2 = (opts) ->
  self = {}
  self.opts = opts
  self.account_name = opts.account_name

  canvas = $("##{opts.canvas}")
  panelVC_list = []
  hide_stopped = false

  self.show_ec2_instances = (regions) ->
    regions ?= region_list
    for region in regions
      $.get("/api/ec2/?region=#{region}&account_name=#{self.account_name}").done (response) ->
        if response.ec2_list && response.ec2_list.length > 0
          rc = $("<div>").append($("<h1>").html(response.region))
          canvas.append(rc)
          panelVC = AWSSC.PanelViewController(canvas: rc)
          panelVC.add_models(response.ec2_list, response.region)
          panelVC_list.push(panelVC)

  $("##{opts.reload}").on "click", ->
    for panelVC in panelVC_list
      panelVC.reload_all()

  $("##{opts.toggle_hide_stop}").on "click", ->
    hide_stopped = !hide_stopped
    for panelVC in panelVC_list
      panelVC.toggle_hide_stop(hide_stopped)

  $("##{opts.filter_text}").on "change", (e) ->
    filterText = e.target.value
    for panelVC in panelVC_list
      panelVC.filter_instance(filterText)

  return self

AWSSC.EC2Model = (data) ->
  API_BASE = "/api/ec2/"
  self = {}
  self.data = data
  self.region = data.region
  self.account_name = data.account_name
  api_params = ->
    region: self.region
    account_name: self.account_name
  polling_sec = 10000

  self.is_running = -> self.data.status == "running"
  self.is_stopped = -> self.data.status == "stopped"

  self.can_start_stop = ->
    self.data.tags['APIStartStop'] == 'YES'

  self.use_stop_only = ->
    self.data.tags['APIAutoOperationMode'] == 'STOP'

  self.run_schedule = ->
    self.data.tags['APIRunSchedule']

  self.update = ->
    $.get("#{API_BASE}#{self.data.ec2_id}", api_params())
    .done (response) ->
        self.data = response.ec2
    .always (response) ->
        console.log response

  check_state = (dfd, ok_func, ng_func) ->
    self.update().done ->
      if ok_func()
        dfd.resolve()
      else if ng_func()
        dfd.fail()
      else
        dfd.notify()
        $.wait(polling_sec).done ->
          check_state(dfd, ok_func, ng_func)

  post_api = (dfd, op_type, params=api_params()) ->
    $.post("#{API_BASE}#{self.data.ec2_id}/#{op_type}", params)
    .always (response) ->
        console.log(response)
    .fail (response) ->
        console.log(response.responseText)
        dfd.reject("ERROR Status=#{response.status}")


  self.start_instance = ->
    dfd = $.Deferred()
    post_api(dfd, "start").done ->
      check_state(dfd, self.is_running, self.is_stopped)
    self.data.status = '-'
    dfd.promise()

  self.stop_instance = ->
    dfd = $.Deferred()
    post_api(dfd, "stop").done ->
      check_state(dfd, self.is_stopped, self.is_running)
    dfd.promise()

  lock_unlock_operation = (op_type, password) ->
    dfd = $.Deferred()
    params = api_params()
    params.password = password
    post_api(dfd, op_type, params).done (response) ->
      if response.success
        $.wait(500).done ->
          dfd.resolve()
      else
        dfd.reject(response.message)
    dfd.promise()

  self.lock_operation = (password) ->
    lock_unlock_operation("lock", password)

  self.unlock_operation = (password) ->
    lock_unlock_operation("unlock", password)

  self.update_schedule = (val, use_stop_only) ->
    dfd = $.Deferred()
    params = api_params()
    params.schedule = val
    params.use_stop_only = if use_stop_only then "1" else "0"
    post_api(dfd, "schedule", params).done (response) ->
      if response.success
        dfd.resolve()
      else
        dfd.reject(response.message)
    dfd.promise()

  return self

AWSSC.PanelViewController = (opts) ->
  self = {}
  self.opts = opts
  canvas = opts.canvas
  panel_list = []

  self.add_models = (ec2_list, region) ->
    for ec2 in ec2_list
      ec2.region = region
      ec2model = AWSSC.EC2Model(ec2)
      self.add(ec2model)

  self.reload_all = ->
    for panel in panel_list
      panel.reload()

  self.toggle_hide_stop = (hide_stopped) ->
    for panel in panel_list
      panel.toggle_hide_stop(hide_stopped)


  self.add = (ec2model) ->
    panel = AWSSC.PanelView(ec2model)
    panel_list.push(panel)
    canvas.append(panel.content)
    panel.update_view()
    panel.check_need_update()

  self.filter_instance = (filterText) ->
    for panel in panel_list
      panel.filter(filterText)

  return self

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

AWSSC.PanelView = (model) ->
  self = {}
  self.model = model
  name = model.data.tags.Name
  # construct view and controll
  info_btn = $('<button type="button" class="btn btn-small"><i class="icon icon-info-sign"></i></button>')
  update_btn = $('<button type="button" class="btn btn-small"><i class="icon icon-refresh"></i></button>')
  start_stop_btn = $('<button type="button" class="btn btn-default ec2-start-stop">')
  lock_unlock_btn = $('<button type="button" class="btn btn-small"></button>')
  edit_schedule_btn = $('<button type="button" class="btn btn-small"><i class="icon icon-edit"> <i class="icon icon-calendar"></button>')
  schedule_element = $('<span class="ec2-panel-item-schedule">')
  auto_mode_element = $('<div class="ec2-panel-item-auto-mode">')
  filter_text = null
  hide_stopped = null
  self.content = $('<div class="ec2-panel-item">')
  .append(info_btn)
  .append(update_btn)
  .append(edit_schedule_btn)
  .append(lock_unlock_btn)
  .append($('<div class="ec2-panel-item-name">'))
  .append($('<div class="ec2-panel-item-type">'))
  .append($('<div class="ec2-panel-item-launch-time">'))
  .append($('<div class="ec2-panel-item-status">'))
  .append($('<span>').html("Schedule: "))
  .append(schedule_element)
  .append(auto_mode_element)
  .append($("<div>").append(start_stop_btn))
  .append($('<div class="ec2-panel-item-cost">').html("-"))

  confirm_action = (msg) ->
    dfd = $.Deferred()
    a = Math.floor(Math.random() * 40) + 10
    b = Math.floor(Math.random() * 40) + 10
    AWSSC.ModalPrompt().show
      title: "Are you sure?"
      body: "#{msg}<br/>#{a} + #{b} == ??"
    .done (val) ->
      ret = (a + b == Math.floor(val))
      if ret
        dfd.resolve()
      else
        dfd.reject()
    .fail ->
      dfd.reject()
    dfd.promise()

  confirm_admin = (msg) ->
    AWSSC.ModalPrompt().show
      title: "Admin Auth"
      body: "#{msg}<br/>Please Input Admin Password"

  show_message = (msg, title) ->
    AWSSC.ModalDialog().show
      title: title
      body: msg

  info_btn.on "click", ->
    data = self.model.data
    info = ["",
      "ID: #{data.ec2_id}"
      "Name: #{name}"
      "type: #{data.instance_type}"
      "private IP: #{data.private_ip}"
      "public IP: #{data.public_ip}"
      "status: #{data.status}"
      "tags: <ul><li>#{("#{k}: #{v}" for k,v of data.tags).join("</li><li>")}</li></ul>"
    ].join("<br>")
    show_message(info, name)

  start_stop_btn.on "click", ->
    if model.is_running()
      prm = confirm_action("Do you really want to STOP '#{name}' ?")
      .fail ->
        show_message("Canceled", "info")
      .then ->
        model.stop_instance()
    else if model.is_stopped()
      prm = confirm_action("Do you really want to START '#{name}' ?")
      .fail ->
          show_message("Canceled", "info")
      .then ->
        model.start_instance()
    if prm
      self.update_view()
      prm.progress ->
        self.update_view()
      .always ->
        self.update_view()

  update_btn.on "click", self.reload

  lock_unlock_btn.on "click", ->
    if self.model.can_start_stop()
      prm = confirm_admin("Do you really want to LOCK<br/> '#{name}' ?").then (password) ->
        self.model.lock_operation(password)
    else
      prm = confirm_admin("Do you really want to UNLOCK '#{name}' ?").then (password) ->
        self.model.unlock_operation(password)
    if prm
      prm.done ->
        model.update().done ->
          self.update_view()
      .fail (reason) ->
        show_message(reason, "failure") if reason


  edit_schedule_btn.on "click", ->
    checkbox = $('<input type="checkbox">')
    if model.use_stop_only()
      checkbox.prop("checked", true)
    extra = $('<div>').append(checkbox).append($("<span> 自動STARTは行わない</span>"))
    AWSSC.ModalPrompt().show
      title: "Enter Schedule"
      body: "ex1) 月-金 && 9-21<br/>ex2) 月,水,金 && 9-12,13-20<br/>ex3) 9-21"
      value: self.model.run_schedule() || "月-金 && 10-22"
      extra: extra
    .done (val) ->
        model.update_schedule(val, checkbox.prop("checked"))
        .done ->
            model.update().done ->
              self.update_view()
        .fail (reason) ->
            show_message(reason, "failure") if reason

  self.check_need_update = (expire_span=3600) ->
    updated_time = new Date(self.model.data.updated_at)
    now = new Date()
    if (now - updated_time)/1000 > expire_span
      self.model.update().done -> self.update_view()

  self.update_view = ->
    data = self.model.data
    launch_time = new Date(data.launch_time)
    now = new Date()
    hours = Math.floor((now - launch_time)/1000/3600)
    cost_per_hour = Math.floor(cost_table[data.instance_type] * region_rate["ap-southeast-1"] * 10000) / 10000
    cost = Math.floor(cost_per_hour * hours)
    self.content.find(".ec2-panel-item-name").html(data.tags.Name)
    self.content.find(".ec2-panel-item-type").html(data.instance_type).addClass(data.instance_type.replace(".", ""))
    self.content.find(".ec2-panel-item-launch-time").html(launch_time.toLocaleString())
    self.content.find(".ec2-panel-item-schedule").html(self.model.run_schedule() || "-")
    item_status = self.content.find(".ec2-panel-item-status").html(data.status).removeClass("running stopped")
    if model.is_running()
      self.content.find(".ec2-panel-item-cost").html("#{hours}H × #{cost_per_hour}$ ≒ #{cost}$")
      self.content.find(".ec2-start-stop").html("STOP")
      item_status.addClass(data.status)
    else if model.is_stopped()
      self.content.find(".ec2-start-stop").html("START")
      item_status.addClass(data.status)
    else
      self.content.find(".ec2-start-stop").append('<i class="icon icon-spinner">')

    unless model.can_start_stop()
      start_stop_btn.hide()
      edit_schedule_btn.hide()
      lock_unlock_btn.html('<i class="icon icon-hand-right"> <i class="icon icon-unlock">')
      auto_mode_element.html("")
    else
      start_stop_btn.show()
      edit_schedule_btn.show()
      auto_mode_element.html(if self.model.use_stop_only() then "AUTO Stop ONLY" else "AUTO Stop & Start")
      lock_unlock_btn.html('<i class="icon icon-hand-right"> <i class="icon icon-lock">')
    check_hide_panel()

  check_hide_panel = ->
    willShow = true
    if self.model.data.status == 'stopped' && hide_stopped
      willShow = false
    if willShow && filter_text
      willShow = false
      ft = filter_text.toLocaleLowerCase()
      for k, v of self.model.data.tags
        if v && v.toLocaleLowerCase().indexOf(ft) >= 0
          willShow = true
          break
    if willShow
      self.content.show()
    else
      self.content.hide()

  self.reload = ->
    self.model.update().done self.update_view

  self.toggle_hide_stop = (hideStopped) ->
    hide_stopped = hideStopped
    check_hide_panel()


  self.filter = (filterText) ->
    filter_text = filterText
    check_hide_panel()


  return self

cost_table =   # virginia, US doller per hour
  "m3.xlarge": 0.45
  "m3.2xlarge": 0.9
  "m1.small": 0.06
  "m1.medium": 0.12
  "m1.large": 0.24
  "m1.xlarge": 0.48
  "c3.large": 0.15
  "c3.xlarge": 0.3
  "c3.2xlarge": 0.6
  "c3.4xlarge": 1.2
  "c3.8xlarge": 2.4
  "c1.medium": 0.145
  "c1.xlarge": 0.58
  "cc2.8xlarge": 2.4
  "g2.2xlarge": 0.65
  "cg1.4xlarge": 2.1
  "m2.xlarge": 0.41
  "m2.2xlarge": 0.82
  "m2.4xlarge": 1.64
  "cr1.8xlarge": 3.5
  "i2.xlarge": 0.853
  "i2.2xlarge": 1.705
  "i2.4xlarge": 3.41
  "i2.8xlarge": 6.82
  "hs1.8xlarge": 4.6
  "hi1.4xlarge": 3.1
  "t1.micro": 0.02

region_rate =
  "ap-southeast-1": 8/6.0

region_list = [
  "us-east-1"
  "us-west-2"
  "us-west-1"
  "eu-west-1"
  "ap-southeast-1"
  "ap-southeast-2"
  "ap-northeast-1"
  "sa-east-1"
]