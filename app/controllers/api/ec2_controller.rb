class Api::Ec2Controller < ApplicationController
  def index
    aws = AWSService.new
    ec2_list = aws.ec2_list_as_model
    render :json => {:ec2_list => ec2_list}
  end

  def show
    ec2_id = params[:ec2_id]
    aws = AWSService.new
    render :json => aws.fetch_detail(ec2_id)
  end
end
