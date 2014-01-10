class AddColumnToEc2Cache < ActiveRecord::Migration
  def change
    add_column :ec2_caches, :public_ip, :string
    add_column :ec2_caches, :private_ip, :string
  end
end
