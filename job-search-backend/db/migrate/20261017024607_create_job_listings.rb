class CreateJobListings < ActiveRecord::Migration[8.1]
  def change
    create_table :job_listings do |t|
      t.string   :board_source,          null: false
      t.text     :company,               null: false
      t.text     :job_title,             null: false
      t.text     :location
      t.date     :job_posted_date,       null: false
      t.string   :employment_type,       null: false
      t.string   :remote_type,           null: false, default: "on-site"
      t.text     :salary_range,          null: false, default: "N/A"
      t.text     :hourly_rate,           null: false, default: "N/A"
      t.text     :job_description,       null: false
      t.text     :url,                   null: false
      t.text     :application_url,       default: "N/A"
      t.text     :posted_by,             default: "N/A"
      t.text     :poster_contact_number, default: "N/A"
      t.text     :poster_email,          default: "N/A"
      t.datetime :date_saved,            null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.string   :status,                null: false, default: "active"
      t.integer  :joe_status,            null: false, default: 0
      t.datetime :archived_at
    end
  end
end
