# coding: utf-8
require 'config'


class Tasks::ExecScheduleTask
  def self.execute
    Rails.logger.info('ExecScheduleTask Start')
    @config = EnvConfig.new
    @config['aws_account'].keys.each do |account_name|
      process_account(account_name)
    end
  end

  def self.process_account(account_name)
    @regions ||= AWSService.new(:account_name => account_name).regions
    @regions.each do |region|
      process_account_region(account_name, region.name)
    end
  end

  def self.process_account_region(account_name, region_name)
    Rails.logger.info("account: #{account_name}, region: #{region_name}")
    account = @config['aws_account'][account_name]
    aws = AWSService.new(:region => region_name, :account_name => account_name)
    aws.ec2_list.each do |ec2|
      Rails.logger.debug("account: #{account_name}, region: #{region_name}, ec2: #{ec2.id}")
      check_schedule(ec2)
    end
  end

  def self.check_schedule(ec2)
    schedule = ec2.tags[AWSService::TAG_RUN_SCHEDULE_KEY]
    is_allow = ec2.tags[AWSService::TAG_CAN_OPERATION_KEY] == AWSService::TAG_CAN_OPERATION_YES
    if schedule and is_allow
      plan = TimePlan.parse(schedule)
      now = Time.now
      Rails.logger.info("==================== ec2: #{ec2.id} #{ec2.tags['Name']} schedule: #{schedule}")
      if plan.include?(now.wday, now.hour)
        if ec2.status == :stopped
          Rails.logger.info("==================== ec2: #{ec2.id} schedule: #{schedule} -> START")
          ec2.start
        end
      else
        if ec2.status == :running
          Rails.logger.info("==================== ec2: #{ec2.id} schedule: #{schedule} -> STOP")
          ec2.stop
        end
      end
    end
  end
end