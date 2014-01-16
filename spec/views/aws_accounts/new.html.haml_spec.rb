require 'spec_helper'

describe "aws_accounts/new" do
  before(:each) do
    assign(:aws_account, stub_model(AwsAccount,
      :name => "MyString",
      :aws_access_key_id => "MyString",
      :aws_secret_access_key => "MyString",
      :admin_password => "MyString"
    ).as_new_record)
  end

  it "renders new aws_account form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", aws_accounts_path, "post" do
      assert_select "input#aws_account_name[name=?]", "aws_account[name]"
      assert_select "input#aws_account_aws_access_key_id[name=?]", "aws_account[aws_access_key_id]"
      assert_select "input#aws_account_aws_secret_access_key[name=?]", "aws_account[aws_secret_access_key]"
      assert_select "input#aws_account_admin_password[name=?]", "aws_account[admin_password]"
    end
  end
end
