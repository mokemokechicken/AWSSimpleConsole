require 'config'
require 'aws'

class AWSService
  attr_reader :opts
  TAG_CAN_OPERATION_KEY = 'APIStartStop'
  TAG_CAN_OPERATION_YES = 'YES'
  TAG_CAN_OPERATION_NO  = 'NO'

  TAG_RUN_SCHEDULE_KEY  = 'APIRunSchedule'

  def initialize(opts = {})
    @config = EnvConfig.new
    @opts = opts
    @opts[:region] ||= 'ap-southeast-1'
    @opts[:account_name] ||= 'YumemiDev'
    setup(@opts[:account_name])
  end

  def setup(account_name)
    @account = @config['aws_account'][account_name.to_s]
    AWS.config(:access_key_id => @account['aws_access_key_id'], :secret_access_key => @account['aws_secret_access_key'])
  end

  def check_admin_password(password)
    @account['admin_password'] == password.to_s
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

  def change_operation_tag(ec2_id, to_enable)
    ec2 = ec2_instance(ec2_id)
    tag = ec2.add_tag(TAG_CAN_OPERATION_KEY, {:value => to_enable ? TAG_CAN_OPERATION_YES : TAG_CAN_OPERATION_NO})
    if tag
      ret = {:success => true, :message => 'OK'}
    else
      ret = {:success => false, :message => tag}
    end
    ret
  end

  def lock(ec2_id)
    change_operation_tag(ec2_id, false)
  end

  def unlock(ec2_id)
    change_operation_tag(ec2_id, true)
  end

  def update_schedule(ec2_id, schedule)
    plan = TimePlan.parse(schedule)
    ec2 = ec2_instance(ec2_id)
    ec2.add_tag(TAG_RUN_SCHEDULE_KEY, {:value => schedule})
    return {:success => true, :message => 'OK'}
  end
end



