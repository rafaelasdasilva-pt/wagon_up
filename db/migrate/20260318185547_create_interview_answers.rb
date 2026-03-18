class CreateInterviewAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_answers do |t|
      t.references :interview_session, null: false, foreign_key: true
      t.text :question
      t.text :answer
      t.text :feedback
      t.integer :score
      t.integer :position

      t.timestamps
    end
  end
end
