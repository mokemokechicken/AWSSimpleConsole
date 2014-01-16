class CreateAwsAccounts < ActiveRecord::Migration
  def change
    create_table :aws_accounts do |t|
      t.string :name
      t.string :aws_access_key_id
      t.string :aws_secret_access_key
      t.string :admin_password

      t.timestamps
    end
  end
end
