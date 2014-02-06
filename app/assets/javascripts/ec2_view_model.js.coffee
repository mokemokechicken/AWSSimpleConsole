AWSSC = window.AWSSC = window.AWSSC ? {}

AWSSC.EC2ViewModel = (parent, in_data) ->
  self = {}
  self.data = ko.observable in_data
  self.region = in_data.region
  self.account_name = in_data.account_name
  self.name = in_data.tags.Name

  api_params = ->
    region: self.region
    account_name: self.account_name
  polling_sec = 10000

  # view event handlers
  self.onReload = ->
    self.update()

  self.onInfo = ->
    data = self.data()
    info = ["",
            "ID: #{data.ec2_id}"
            "Name: #{self.name}"
            "type: #{data.instance_type}"
            "private IP: #{data.private_ip}"
            "public IP: #{data.public_ip}"
            "status: #{data.status}"
            "tags: <ul><li>#{("#{k}: #{v}" for k,v of data.tags).join("</li><li>")}</li></ul>"
    ].join("<br>")
    parent.show_message(info, name)

  self.onLockUnlock = ->
    if self.can_start_stop()
      prm = parent.confirm_admin("Do you really want to LOCK<br/> '#{self.name}' ?").then (password) ->
        self.lock_operation(password)
    else
      prm = parent.confirm_admin("Do you really want to UNLOCK '#{self.name}' ?").then (password) ->
        self.unlock_operation(password)
    if prm
      prm.done ->
        self.update()
      .fail (reason) ->
          parent.show_message(reason, "failure") if reason

  self.onEditSchedule = ->
    checkbox = $('<input type="checkbox">')
    if self.use_stop_only()
      checkbox.prop("checked", true)
    extra = $('<div>').append(checkbox).append($("<span> 自動STARTは行わない</span>"))
    AWSSC.ModalPrompt().show
      title: "Enter Schedule"
      body: "ex1) 月-金 && 9-21<br/>ex2) 月,水,金 && 9-12,13-20<br/>ex3) 9-21"
      value: self.run_schedule() || "月-金 && 10-22"
      extra: extra
    .done (val) ->
        self.update_schedule(val, checkbox.prop("checked"))
        .done ->
            self.update()
        .fail (reason) ->
            show_message(reason, "failure") if reason

  # logic
  self.is_running = ko.computed -> self.data().status == "running"
  self.is_stopped = ko.computed -> self.data().status == "stopped"
  self.is_state_changing = ko.computed -> !self.is_running() && !self.is_stopped()

  self.can_start_stop = ko.computed ->
    self.data().tags['APIStartStop'] == 'YES'

  self.use_stop_only = ko.computed ->
    self.data().tags['APIAutoOperationMode'] == 'STOP'

  self.run_schedule = ko.computed ->
    self.data().tags['APIRunSchedule']

  self.update = ->
    $.get("#{AWSSC.config.API_BASE}#{self.data().ec2_id}", api_params())
    .done (response) ->
        self.data(response.ec2)
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
    $.post("#{AWSSC.config.API_BASE}#{self.data().ec2_id}/#{op_type}", params)
    .always (response) ->
        console.log(response)
    .fail (response) ->
        console.log(response.responseText)
        dfd.reject("ERROR Status=#{response.status}")


  self.start_instance = ->
    dfd = $.Deferred()
    post_api(dfd, "start").done ->
      check_state(dfd, self.is_running, self.is_stopped)
    data = self.data()
    data.status = '-'
    self.data(data)
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

  # properties
  self.launch_time = ko.computed ->
    new Date(self.data().launch_time).toLocaleDateString()

  self.instance_type = self.data().instance_type
  self.hideStop = ko.observable(false)
  self.filterText = ko.observable("")

  self.status = ko.computed -> self.data().status

  self.cost = ko.computed ->
    now = new Date()
    data = self.data()
    launch_time = new Date(data.launch_time)
    hours = Math.floor((now - launch_time)/1000/3600)
    cost_per_hour = Math.floor(cost_table[data.instance_type] * region_rate["ap-southeast-1"] * 10000) / 10000
    cost = Math.floor(cost_per_hour * hours)
    "#{hours}H × #{cost_per_hour}$ ≒ #{cost}$"

  self.instanceTypeCSS = ko.computed ->
    self.data().instance_type.replace(".", "")

  self.toggle_hide_stop = (hideStopped) ->
    self.hideStop(hideStopped)

  self.isIncludeFilterText = ko.computed ->
    if !self.filterText()
      true
    else
      ft = self.filterText().toLocaleLowerCase()
      for k, v of self.data().tags
        if v && v.toLocaleLowerCase().indexOf(ft) >= 0
          return true
      false

  self.shouldHide = ko.computed ->
    (self.hideStop() && self.is_stopped()) || !self.isIncludeFilterText()

  self.check_need_update = (expire_span=86400) ->
    updated_time = new Date(self.data().updated_at)
    now = new Date()
    return (now - updated_time)/1000 > expire_span

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
