class AddIndexToAwsAccount < ActiveRecord::Migration
  def change
    add_index :aws_accounts, :name, :unique => true
  end
end
