class CreateConfig < ActiveRecord::Migration[8.1]
  def change
    # Table name is config (singular) to match the PRD
    create_table :config do |t|
      t.text :local_app_data,   null: false, default: "/localAppData/resume"
      t.text :delimiter,        null: false, default: "@@@startdelim@@@"
      t.text :compare_prompt
    end
  end
end
