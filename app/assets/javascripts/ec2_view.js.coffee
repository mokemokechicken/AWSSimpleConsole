AWSSC = AWSSC ? {}


AWSSC.EC2 = (opts) ->
  that = {}
  that.opts = opts

  that.show_ec2_instances = ->
    $.get('/api/ec2/').done (response) ->
      console.log response
      response

  that

window.AWSSC = AWSSC
