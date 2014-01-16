require 'spec_helper'

describe "aws_accounts/index" do
  before(:each) do
    assign(:aws_accounts, [
      stub_model(AwsAccount,
        :name => "Name",
        :aws_access_key_id => "Aws Access Key",
        :aws_secret_access_key => "Aws Secret Access Key",
        :admin_password => "Admin Password"
      ),
      stub_model(AwsAccount,
        :name => "Name",
        :aws_access_key_id => "Aws Access Key",
        :aws_secret_access_key => "Aws Secret Access Key",
        :admin_password => "Admin Password"
      )
    ])
  end

  it "renders a list of aws_accounts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Aws Access Key".to_s, :count => 2
    assert_select "tr>td", :text => "Aws Secret Access Key".to_s, :count => 2
    assert_select "tr>td", :text => "Admin Password".to_s, :count => 2
  end
end
