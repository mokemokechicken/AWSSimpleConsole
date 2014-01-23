class Api::Ec2Controller < ApplicationController
  before_filter :authenticate_user!

  def init_aws_service(params)
    AWSService.new(:region => params[:region], :account_name => params[:account_name])
  end

  def index
    aws = init_aws_service(params)
    cache_expire = params[:no_cache] ? -1 : 10000000000000
    ec2_list = aws.ec2_list_as_model(cache_expire).sort_by {|x| x.tags['Name'].to_s.strip}
    render :json => {:ec2_list => ec2_list, :region => params[:region], :account_name => aws.account_name}
  end

  def show
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    render :json => {:ec2 => aws.refresh(ec2_id)}
  end

  def start
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    ret = aws.start(ec2_id)
    record_log(:start, ec2_id, nil)
    render :json => {:result => ret}
  end

  def stop
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    ret = aws.stop(ec2_id)
    record_log(:stop, ec2_id, nil)
    render :json => {:result => ret}
  end

  def lock
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    if aws.check_admin_password(params[:password])
      ret = aws.lock(ec2_id)
      record_log(:lock, ec2_id, nil)
    else
      ret = {:success => false, :message => 'wrong password'}
    end
    render :json => {:success => ret[:success], :message => ret[:message]}
  end

  def unlock
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    if aws.check_admin_password(params[:password])
      ret = aws.unlock(ec2_id)
      record_log(:unlock, ec2_id, nil)
    else
      ret = {:success => false, :message => 'wrong password'}
    end
    render :json => {:success => ret[:success], :message => ret[:message]}
  end

  def schedule
    ec2_id = params[:ec2_id]
    use_stop_only = params[:use_stop_only].to_s == '1'
    aws = init_aws_service(params)
    ret = aws.update_schedule(ec2_id, params[:schedule], use_stop_only)
    if ret[:success]
      record_log(:schedule, ec2_id, {:schedule => params[:schedule], :use_stop_only => use_stop_only})
    end
    render :json => {:success => ret[:success], :message => ret[:message]}
  end

  private
  def record_log(op, target, options=nil)
    options = JSON.dump(options) if options
    OperationLog.create(:username => current_user.email, :op => op, :target => target, :options => options)
  end
end
