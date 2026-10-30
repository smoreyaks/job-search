class CreateTracking < ActiveRecord::Migration[8.1]
  def change
    # Table name is tracking (singular) to match the PRD
    create_table :tracking do |t|
      t.references :job_listing, null: false, foreign_key: true
      t.references :resume,      null: false, foreign_key: true
      t.references :comparison,  null: false, foreign_key: true
      t.bigint     :cover_letter_id, null: false
      t.boolean    :applied,             null: false, default: false
      t.date       :date_applied
      t.boolean    :response_received,   null: false, default: false
      t.boolean    :follow_up_needed,    null: false, default: false
      t.date       :interview_date
      t.text       :notes
      t.date       :next_follow_up_date
    end

    add_index :tracking, :cover_letter_id
    add_foreign_key :tracking, :cover_table, column: :cover_letter_id
  end
end
