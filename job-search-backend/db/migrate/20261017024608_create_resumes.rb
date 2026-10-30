class CreateResumes < ActiveRecord::Migration[8.1]
  def change
    create_table :resumes do |t|
      t.text     :file_name,      null: false
      t.datetime :date_uploaded,  null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.text     :version_note,   default: "N/A"
      t.text     :file_path,      null: false
      t.text     :extracted_text
      t.datetime :archived_at
    end
  end
end
