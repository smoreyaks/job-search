class CreateComparisons < ActiveRecord::Migration[8.1]
  def change
    create_table :comparisons do |t|
      t.references :resume,      null: false, foreign_key: true
      t.references :job_listing, null: false, foreign_key: true
      t.decimal    :match_score, null: false, precision: 5, scale: 2
      t.text       :resume_suggestions
      t.datetime   :comparison_datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
