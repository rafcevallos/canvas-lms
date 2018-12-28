class CreateStandards < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :standards do |t|
      t.integer :ext_id
      t.string :code
      t.string :description

      t.timestamps
    end
  end
end
