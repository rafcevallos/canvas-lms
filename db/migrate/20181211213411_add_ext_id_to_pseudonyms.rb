class AddExtIdToPseudonyms < ActiveRecord::Migration[5.1]
  tag :predeploy

  def self.up
    add_column :pseudonyms, :ext_id, :integer
  end

  def self.down
    remove_column :pseudonyms, :ext_id
  end
end
