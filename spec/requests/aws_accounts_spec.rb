require 'spec_helper'

describe "AwsAccounts" do
  describe "GET /aws_accounts" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get aws_accounts_path
      response.status.should be(200)
    end
  end
end
