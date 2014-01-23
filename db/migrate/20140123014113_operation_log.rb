class OperationLog < ActiveRecord::Migration
  def change
    create_table :operation_logs do |t|
      t.string :username
      t.string :op
      t.string :target
      t.string :options

      t.timestamps
    end
  end
end
