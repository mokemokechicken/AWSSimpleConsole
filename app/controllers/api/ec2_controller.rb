class Api::Ec2Controller < ApplicationController
  def init_aws_service(params)
    AWSService.new(:region => params[:region])
  end

  def index
    aws = init_aws_service(params)
    cache_expire = params[:no_cache] ? 30 : nil
    ec2_list = aws.ec2_list_as_model(cache_expire)
    render :json => {:ec2_list => ec2_list, :region => params[:region]}
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
    render :json => {:result => ret}
  end

  def stop
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    ret = aws.stop(ec2_id)
    render :json => {:result => ret}
  end

  def lock
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    if aws.check_admin_password(params[:password])
      ret = aws.lock(ec2_id)
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
    else
      ret = {:success => false, :message => 'wrong password'}
    end
    render :json => {:success => ret[:success], :message => ret[:message]}
  end

  def schedule
    ec2_id = params[:ec2_id]
    aws = init_aws_service(params)
    ret = aws.update_schedule(ec2_id, params[:schedule])
    render :json => {:success => ret[:success], :message => ret[:message]}
  end
end
