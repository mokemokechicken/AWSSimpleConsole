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