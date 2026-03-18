class CreateAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :analyses do |t|
      t.references :user, null: false, foreign_key: true
      t.text :summary
      t.text :skills
      t.jsonb :raw_json
      t.text :cv_text

      t.timestamps
    end
  end
end
