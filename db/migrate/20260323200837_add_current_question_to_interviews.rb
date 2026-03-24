class AddCurrentQuestionToInterviews < ActiveRecord::Migration[8.1]
  def change
    add_column :interviews, :current_question, :text
  end
end
