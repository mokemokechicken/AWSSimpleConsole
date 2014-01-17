require 'config'
require 'aws'

class AWSService
  attr_reader :opts
  TAG_CAN_OPERATION_KEY = 'APIStartStop'
  TAG_CAN_OPERATION_YES = 'YES'
  TAG_CAN_OPERATION_NO  = 'NO'

  TAG_RUN_SCHEDULE_KEY  = 'APIRunSchedule'

  TAG_AUTO_OPERATION_MODE_KEY = 'APIAutoOperationMode'
  TAG_AUTO_OPERATION_MODE_STOP_ONLY = 'STOP'
  TAG_AUTO_OPERATION_MODE_STOP_START = 'STOP,START'

  def initialize(opts = {})
    @config = EnvConfig.new
    @opts = opts
    @opts[:region] ||= 'ap-southeast-1'
    @opts[:account_name] = @opts[:account_name].to_s.empty? ? AwsAccount.all.first.name : @opts[:account_name]
    setup(@opts[:account_name])
  end

  def setup(account_name)
    @account = AwsAccount.find_by_name(account_name)
    AWS.config(:access_key_id => @account.aws_access_key_id, :secret_access_key => @account.aws_secret_access_key)
  end

  def check_admin_password(password)
    @account.admin_password == password.to_s
  end

  def account_name
    @opts[:account_name]
  end

  def regions
    @regions ||= AWS.regions
  end

  def ec2
    AWS::EC2.new(:region => @opts[:region])
  end

  def elb
    @elb ||= AWS::ELB.new(:region => @opts[:region])
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
      re_register_to_elb(ec2.id)
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

  def re_register_to_elb(ec2_id)
    elb.load_balancers.each do |lb|
      instance_id_list = lb.instances.to_a.map{|x| x.id}
      if instance_id_list.include?(ec2_id)
        ec2 = lb.instances[ec2_id]
        ec2.remove_from_load_balancer
        lb.instances.register(ec2)
      end
    end
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

  def change_auto_operation_mode(ec2_id, mode=:stop_start)
    ec2 = ec2_instance(ec2_id)
    case mode
      when :stop_only
        tag = ec2.add_tag(TAG_AUTO_OPERATION_MODE_KEY, {:value => TAG_AUTO_OPERATION_MODE_STOP_ONLY})
      when :stop_start
        tag = ec2.add_tag(TAG_AUTO_OPERATION_MODE_KEY, {:value => TAG_AUTO_OPERATION_MODE_STOP_START})
    end
    if tag
      ret = {:success => true, :message => 'OK'}
    else
      ret = {:success => false, :message => tag}
    end
    ret
  end

  def update_schedule(ec2_id, schedule, use_stop_only=false)
    TimePlan.parse(schedule)
    ec2 = ec2_instance(ec2_id)
    ec2.add_tag(TAG_RUN_SCHEDULE_KEY, {:value => schedule})
    change_auto_operation_mode(ec2_id, use_stop_only ? :stop_only : :stop_start)
    return {:success => true, :message => 'OK'}
  end
end



