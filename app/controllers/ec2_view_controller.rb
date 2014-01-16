class Ec2ViewController < ApplicationController
  before_filter :authenticate_user!

  def index
    @account_list = AwsAccount.all
    @account_name = params[:account_name] || @account_list.first.name
  end
end
