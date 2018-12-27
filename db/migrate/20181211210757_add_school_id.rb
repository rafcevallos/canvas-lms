class AddSchoolId < ActiveRecord::Migration[5.1]
  tag :predeploy

  def self.up
    add_column :pseudonyms, :school_id, :integer
  end

  def self.down
    remove_column :pseudonyms, :school_id
  end
end
