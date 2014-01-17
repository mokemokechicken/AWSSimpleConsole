# coding: utf-8
require 'config'

class Tasks::ExecScheduleTask
  def self.execute
    new.run
  end

  def run
    Rails.logger.info('ExecScheduleTask Start')
    @config = EnvConfig.new
    @update_list = []
    AwsAccount.all.each do |account|
      process_account(account.name)
    end
    @update_list.each do |ec2|
      Rails.logger.info("=============================== Resync #{ec2.id}: #{ec2.tags['Name']} =============================")
      Ec2Cache.fetch(ec2).sync(ec2)
    end
  end

  def process_account(account_name)
    @regions ||= AWSService.new(:account_name => account_name).regions
    @regions.each do |region|
      process_account_region(account_name, region.name)
    end
  end

  def process_account_region(account_name, region_name)
    Rails.logger.info("account: #{account_name}, region: #{region_name}")
    # account = @config['aws_account'][account_name]
    aws = AWSService.new(:region => region_name, :account_name => account_name)
    aws.ec2_list.each do |ec2|
      Rails.logger.debug("account: #{account_name}, region: #{region_name}, ec2: #{ec2.id}")
      begin
        check_schedule(aws, ec2)
      rescue => e
        Rails.logger.error(e.to_s)
      end
    end
  end

  def is_allow(ec2)
    ec2.tags[AWSService::TAG_CAN_OPERATION_KEY] == AWSService::TAG_CAN_OPERATION_YES
  end

  def check_schedule(aws, ec2)
    schedule = ec2.tags[AWSService::TAG_RUN_SCHEDULE_KEY]
    if schedule and is_allow(ec2)
      plan = TimePlan.parse(schedule)
      now = Time.zone.now.in_time_zone(@config['timezone'])
      Rails.logger.info("==================== ec2: #{ec2.id} #{ec2.tags['Name']} schedule: #{schedule}")
      if plan.include?(now.wday, now.hour)
        mode = ec2.tags[AWSService::TAG_AUTO_OPERATION_MODE_KEY]
        if ec2.status == :stopped && (!mode || mode == AWSService::TAG_AUTO_OPERATION_MODE_STOP_START)
          Rails.logger.info("==================== ec2: #{ec2.id} schedule: #{schedule} -> START")
          aws.start(ec2.id)
          @update_list << ec2
        end
      else
        if ec2.status == :running
          Rails.logger.info("==================== ec2: #{ec2.id} schedule: #{schedule} -> STOP")
          aws.stop(ec2.id)
          @update_list << ec2
        end
      end
    end
  end
end