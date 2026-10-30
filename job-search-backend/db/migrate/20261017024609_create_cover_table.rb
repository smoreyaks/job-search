class CreateCoverTable < ActiveRecord::Migration[8.1]
  def change
    # Table name is cover_table (singular) to match the PRD
    create_table :cover_table do |t|
      t.text     :file_name,     null: false
      t.datetime :date_uploaded, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.text     :version_note,  default: "N/A"
      t.text     :file_path,     null: false
      t.datetime :archived_at
    end
  end
end
