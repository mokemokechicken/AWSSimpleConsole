AWSSC = AWSSC ? {}
window.AWSSC = AWSSC


AWSSC.EC2 = (opts) ->
  self = {}
  self.opts = opts

  canvas = $("##{opts.canvas}")
  panelVC_list = []
  hide_stopped = false

  self.show_ec2_instances = (regions) ->
    regions ?= region_list
    for region in regions
      $.get("/api/ec2/?region=#{region}").done (response) ->
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

  return self

AWSSC.EC2Model = (data) ->
  self = {}
  self.data = data

  self.update = ->
    $.get("/api/ec2/#{self.data.ec2_id}?region=#{self.data.region}").done (response) ->
      console.log response
      self.data = response.ec2
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


  return self

AWSSC.PanelView = (model) ->
  self = {}
  self.model = model
  self.content = $('<div class="ec2-panel-item">')
  .append($('<div class="ec2-panel-item-name">'))
  .append($('<div class="ec2-panel-item-type">'))
  .append($('<div class="ec2-panel-item-launch-time">'))
  .append($('<div class="ec2-panel-item-status">'))
  .append($('<div class="ec2-panel-item-cost">').html("-"))


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
    self.content.find(".ec2-panel-item-status").html(data.status).addClass(data.status)
    if data.status == "running"
      self.content.find(".ec2-panel-item-cost").html("#{hours}H × #{cost_per_hour}$ ≒ #{cost}$")

  self.reload = ->
    self.model.update().done (response) ->
      self.update_view()

  self.toggle_hide_stop = (hide_stopped) ->
    if self.model.data.status == 'stopped' && hide_stopped
      self.content.hide()
    if !hide_stopped
      self.content.show()




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