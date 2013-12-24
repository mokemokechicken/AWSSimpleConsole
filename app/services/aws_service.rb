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

  def ec2_list_as_model
    ec2_list.map {|ec2| Ec2Cache.fetch(ec2)}
  end

  def ec2_instance(ec2_id)
    ec2.instances[ec2_id]
  end

  def fetch_detail(ec2_id)
    ec2 = aws.ec2_instance(ec2_id)
    ec2_cache = Ec2Cache.fetch(ec2)
    hash = JSON.parse(ec2_cache.as_json)
    hash[:status] = ec2.status
    return hash
  end
end



