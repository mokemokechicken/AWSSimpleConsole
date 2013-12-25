class CreateEc2Caches < ActiveRecord::Migration
  def change
    create_table :ec2_caches do |t|
      t.string :ec2_id
      t.string :tag_json
      t.string :instance_type
      t.string :status
      t.datetime :launch_time
      t.timestamps
    end
  end
end
