#require 'aws'
#require 'config'
#
#class AWSFactory
#  @config = EnvConfig.new
#  AWS.config(
#      :access_key_id => @config['secret']['aws_access_key_id'],
#      :secret_access_key => @config['secret']['aws_secret_access_key'],
#  )
#
#  def self.ec2(region)
#    AWS::EC2.new(:region => region)
#  end
#end