class CreateStandards < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :standards do |t|
      t.integer :ext_id
      t.string :code
      t.string :description
      t.integer :course_id
      t.integer :school_id
      t.integer :standard_group_id

      t.timestamps
    end

    add_foreign_key :standards, :courses
  end
end
