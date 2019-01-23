class AddSectionPeriodIdsToCourseSection < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    add_column :course_sections, :section_period_ids, :text
  end
end
