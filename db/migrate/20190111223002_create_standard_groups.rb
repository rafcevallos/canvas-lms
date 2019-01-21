class CreateStandardGroups < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :standard_groups do |t|
      t.text :code
      t.text :description

      t.timestamps
    end

    add_column :standards, :standard_group_id, :integer
    add_foreign_key :standards, :standard_groups
  end
end
