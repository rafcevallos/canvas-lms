class AddSrIdToQuizzes < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    add_column :quizzes, :sr_id, :integer
  end
end
