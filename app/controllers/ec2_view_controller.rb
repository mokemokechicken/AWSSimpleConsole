class Ec2ViewController < ApplicationController
  before_filter :authenticate_user!

  def index
    @account_list = AwsAccount.all
    account = @account_list.first
    @account_name = params[:account_name] || (account && account.name)
  end
end
