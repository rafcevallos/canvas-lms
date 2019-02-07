class AddSrIdToCourse < ActiveRecord::Migration[5.1]
  tag :predeploy
  
  def change
    add_column :courses, :sr_id, :integer
  end
end
