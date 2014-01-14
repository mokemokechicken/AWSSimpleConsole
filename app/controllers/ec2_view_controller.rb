require 'config'

class Ec2ViewController < ApplicationController
  before_filter :authenticate_user!

  def index
    config = EnvConfig.new
    @account_name_list = config['aws_account'].keys
    @account_name = params[:account_name]
  end
end
