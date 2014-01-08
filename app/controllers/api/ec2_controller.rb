class Api::Ec2Controller < ApplicationController
  def index
    aws = AWSService.new(:region => params[:region])
    cache_expire = params[:no_cache] ? 30 : nil
    ec2_list = aws.ec2_list_as_model(cache_expire)
    render :json => {:ec2_list => ec2_list, :region => params[:region]}
  end

  def show
    ec2_id = params[:ec2_id]
    aws = AWSService.new(:region => params[:region])
    render :json => {:ec2 => aws.refresh(ec2_id)}
  end

  def start
    ec2_id = params[:ec2_id]
    aws = AWSService.new(:region => params[:region])
    ret = aws.start(ec2_id)
    render :json => {:result => ret}
  end

  def stop
    ec2_id = params[:ec2_id]
    aws = AWSService.new(:region => params[:region])
    ret = aws.stop(ec2_id)
    render :json => {:result => ret}
  end
end
