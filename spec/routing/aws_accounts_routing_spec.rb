require "spec_helper"

describe AwsAccountsController do
  describe "routing" do

    it "routes to #index" do
      get("/aws_accounts").should route_to("aws_accounts#index")
    end

    it "routes to #new" do
      get("/aws_accounts/new").should route_to("aws_accounts#new")
    end

    it "routes to #show" do
      get("/aws_accounts/1").should route_to("aws_accounts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/aws_accounts/1/edit").should route_to("aws_accounts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/aws_accounts").should route_to("aws_accounts#create")
    end

    it "routes to #update" do
      put("/aws_accounts/1").should route_to("aws_accounts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/aws_accounts/1").should route_to("aws_accounts#destroy", :id => "1")
    end

  end
end
