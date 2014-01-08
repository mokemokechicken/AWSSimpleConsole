require 'config'
require 'aws'

class AWSService
  attr_reader :opts

  config = EnvConfig.new
  AWS.config(:access_key_id => config['secret']['aws_access_key_id'], :secret_access_key => config['secret']['aws_secret_access_key'])

  def initialize(opts = {})
    @opts = opts
    @opts[:region] ||= 'ap-southeast-1'
  end

  def regions
    @regions ||= AWS.regions
  end

  def ec2
    AWS::EC2.new(:region => @opts[:region])
  end

  def ec2_list
    ec2.instances.to_a
  end

  def ec2_list_as_model(cache_expire=nil)
    ec2_list.map {|ec2| Ec2Cache.fetch(ec2, cache_expire)}
  end

  def ec2_instance(ec2_id)
    ec2.instances[ec2_id]
  end

  def refresh(ec2_id)
    ec2 = ec2_instance(ec2_id)
    Ec2Cache.fetch(ec2, -1)
  end

  def start(ec2_id)
    ec2 = ec2_instance(ec2_id)
    status = ec2.status
    message = 'OK'
    if status == :stopped
      ec2.start
    else
      message = "NG. status is #{status}, not 'stopped'."
    end
    return {:message => message}
  end

  def stop(ec2_id)
    ec2 = ec2_instance(ec2_id)
    status = ec2.status
    message = 'OK'
    if status == :running
      ec2.stop
    else
      message = "NG. status is #{status}, not 'running'."
    end
    return {:message => message}
  end
end



