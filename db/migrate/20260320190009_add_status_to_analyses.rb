class AddStatusToAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :analyses, :status, :string, default: "processing"
  end
end
