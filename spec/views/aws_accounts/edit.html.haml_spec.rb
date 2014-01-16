require 'spec_helper'

describe "aws_accounts/edit" do
  before(:each) do
    @aws_account = assign(:aws_account, stub_model(AwsAccount,
      :name => "MyString",
      :aws_access_key_id => "MyString",
      :aws_secret_access_key => "MyString",
      :admin_password => "MyString"
    ))
  end

  it "renders the edit aws_account form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", aws_account_path(@aws_account), "post" do
      assert_select "input#aws_account_name[name=?]", "aws_account[name]"
      assert_select "input#aws_account_aws_access_key_id[name=?]", "aws_account[aws_access_key_id]"
      assert_select "input#aws_account_aws_secret_access_key[name=?]", "aws_account[aws_secret_access_key]"
      assert_select "input#aws_account_admin_password[name=?]", "aws_account[admin_password]"
    end
  end
end
