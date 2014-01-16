require 'spec_helper'

describe "aws_accounts/show" do
  before(:each) do
    @aws_account = assign(:aws_account, stub_model(AwsAccount,
      :name => "Name",
      :aws_access_key_id => "Aws Access Key",
      :aws_secret_access_key => "Aws Secret Access Key",
      :admin_password => "Admin Password"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Aws Access Key/)
    rendered.should match(/Aws Secret Access Key/)
    rendered.should match(/Admin Password/)
  end
end
