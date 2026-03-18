class CreateSuggestedRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :suggested_roles do |t|
      t.references :analysis, null: false, foreign_key: true
      t.string :title
      t.text :justification
      t.jsonb :market_fit
      t.integer :position

      t.timestamps
    end
  end
end
