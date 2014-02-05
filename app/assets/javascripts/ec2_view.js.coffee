AWSSC = window.AWSSC = window.AWSSC ? {}

AWSSC.config = AWSSC.config ? {}
AWSSC.config.API_BASE = "/api/ec2/"

$.wait = (duration) ->
  dfd = $.Deferred()
  setTimeout( ->
    dfd.resolve()
  , duration)
  return dfd

AWSSC.EC2 = (opts) ->
  self = {}
  self.opts = opts

  canvas = $("##{opts.canvas}")

  self.show_ec2_instances = (regions) ->
    regions ?= region_list
    for region in regions
      $.get("#{AWSSC.config.API_BASE}?region=#{region}&account_name=#{self.account_name}").done (response) ->
        response.account_name = self.account_name
        viewModel.addRegion(response)

  self.show_message = (msg, title) ->
    AWSSC.ModalDialog().show
      title: title
      body: msg

  self.confirm_admin = (msg) ->
    AWSSC.ModalPrompt().show
      title: "Admin Auth"
      body: "#{msg}<br/>Please Input Admin Password"

  self.confirm_action = (msg) ->
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

  viewModel = EC2PageViewModel(self)
  self.account_name = viewModel.resolve_account_name(opts)
  ko.applyBindings(viewModel, canvas[0])
  return self

EC2PageViewModel = (controller) ->
  model = {}
  regionVCList = []
  # properties
  model.hideStopped = ko.observable(false)
  model.filterText = ko.observable("")
  model.regions = ko.observableArray([])
  # Handlers
  model.onReload = ->
    for panelVC in regionVCList
      panelVC.reload_all()

  model.onToggleHideStop = ->
    model.hideStopped(!model.hideStopped())
    for regionVC in regionVCList
      regionVC.toggle_hide_stop(model.hideStopped())

  model.filterText.subscribe (newValue) ->
    for regionVC in regionVCList
      regionVC.filter_instance(newValue)

  model.addRegion = (region) ->
    if region.ec2_list && region.ec2_list.length > 0
      regionVC = AWSSC.RegionViewModel(model, region)
      regionVC.add_models region.ec2_list,
        region: region.region
        account_name: region.account_name
      model.regions.push regionVC
      regionVCList.push(regionVC)

  model.show_message = controller.show_message
  model.confirm_admin = controller.confirm_admin
  model.confirm_action = controller.confirm_action

  # Storage Access
  model.resolve_account_name = (opts) ->
    localStorage.account_name =
      if opts.account_name
        opts.account_name
      else
        if localStorage.account_name
          localStorage.account_name
        else
          opts.default_account_name
    $("##{opts.account_dropdown}").html(localStorage.account_name) if localStorage.account_name
    localStorage.account_name
  return model



AWSSC.RegionViewModel = (parent, opts) ->
  self = {}
  self.opts = opts
  self.regionName = opts.region
  self.ec2List = ko.observableArray([])

  self.add_models = (list, opts) ->
    for ec2 in list
      ec2.region = opts.region
      ec2.account_name = opts.account_name
      ec2model = AWSSC.EC2ViewModel(self, ec2)
      self.ec2List.push ec2model
      if ec2model.check_need_update()
        ec2model.update()

  self.reload_all = ->
    for ec2 in self.ec2List()
      ec2.reload()

  self.toggle_hide_stop = (hide_stopped) ->
    for ec2 in self.ec2List()
      ec2.toggle_hide_stop(hide_stopped)

  self.filter_instance = (filterText) ->
    for ec2 in self.ec2List()
      ec2.filterText(filterText)

  self.show_message = parent.show_message
  self.confirm_admin = parent.confirm_admin
  self.confirm_action = parent.confirm_action
  return self

AWSSC.EC2PanelView = (model) ->
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

  update_btn.on "click", ->
    self.reload()

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

  self.check_need_update = (expire_span=86400) ->
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