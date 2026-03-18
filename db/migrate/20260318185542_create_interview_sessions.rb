class CreateInterviewSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :suggested_role, null: false, foreign_key: true
      t.integer :overall_score
      t.text :feedback_summary

      t.timestamps
    end
  end
end
