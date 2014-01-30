AWSSC = window.AWSSC = window.AWSSC ? {}

AWSSC.EC2ViewModel = (parent, data) ->
  API_BASE = "/api/ec2/"
  self = {}
  self.data = ko.observable data
  self.region = data.region
  self.account_name = data.account_name
  self.name = data.tags.Name
  api_params = ->
    region: self.region
    account_name: self.account_name
  polling_sec = 10000

  # view event handlers
  self.onReload = ->
    self.update()

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

  # logic
  self.is_running = ko.computed -> self.data().status == "running"
  self.is_stopped = ko.computed -> self.data().status == "stopped"
  self.is_state_changing = ko.computed -> !self.is_running() && !self.is_stopped()

  self.can_start_stop = ko.computed ->
    self.data().tags['APIStartStop'] == 'YES'

  self.use_stop_only = ->
    self.data().tags['APIAutoOperationMode'] == 'STOP'

  self.run_schedule = ->
    self.data().tags['APIRunSchedule']

  self.update = ->
    $.get("#{API_BASE}#{self.data().ec2_id}", api_params())
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
    $.post("#{API_BASE}#{self.data().ec2_id}/#{op_type}", params)
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

  self.startStopBtnLabel = ko.computed ->
    if self.is_running()
      "STOP"
    else if self.is_stopped()
      "START"
    else
      ""


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
