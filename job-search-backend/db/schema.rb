# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_20_095708) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "comparisons", force: :cascade do |t|
    t.bigint "resume_id", null: false
    t.bigint "job_listing_id", null: false
    t.decimal "match_score", precision: 5, scale: 2, null: false
    t.text "resume_suggestions"
    t.datetime "comparison_datetime", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["job_listing_id"], name: "index_comparisons_on_job_listing_id"
    t.index ["resume_id"], name: "index_comparisons_on_resume_id"
  end

  create_table "config", force: :cascade do |t|
    t.text "local_app_data", default: "~/.local/share/job-search-dashboard/resume", null: false
    t.text "delimiter", default: "@@@startdelim@@@", null: false
    t.text "compare_prompt"
  end

  create_table "cover_table", force: :cascade do |t|
    t.text "file_name", null: false
    t.datetime "date_uploaded", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "version_note", default: "N/A"
    t.text "file_path", null: false
    t.datetime "archived_at"
  end

  create_table "job_listings", force: :cascade do |t|
    t.string "board_source", null: false
    t.text "company", null: false
    t.text "job_title", null: false
    t.text "location"
    t.date "job_posted_date", null: false
    t.string "employment_type", null: false
    t.string "remote_type", default: "on-site", null: false
    t.text "salary_range", default: "N/A", null: false
    t.text "hourly_rate", default: "N/A", null: false
    t.text "job_description", null: false
    t.text "url", null: false
    t.text "application_url", default: "N/A"
    t.text "posted_by", default: "N/A"
    t.text "poster_contact_number", default: "N/A"
    t.text "poster_email", default: "N/A"
    t.datetime "date_saved", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "status", default: "active", null: false
    t.integer "joe_status", default: 0, null: false
    t.datetime "archived_at"
    t.string "jsearch_job_id"
    t.datetime "job_offer_expires_at"
    t.index ["jsearch_job_id"], name: "index_job_listings_on_jsearch_job_id"
  end

  create_table "resumes", force: :cascade do |t|
    t.text "file_name", null: false
    t.datetime "date_uploaded", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "version_note", default: "N/A"
    t.text "file_path", null: false
    t.text "extracted_text"
    t.datetime "archived_at"
  end

  create_table "tracking", force: :cascade do |t|
    t.bigint "job_listing_id", null: false
    t.bigint "resume_id", null: false
    t.bigint "comparison_id", null: false
    t.bigint "cover_letter_id", null: false
    t.boolean "applied", default: false, null: false
    t.date "date_applied"
    t.boolean "response_received", default: false, null: false
    t.boolean "follow_up_needed", default: false, null: false
    t.date "interview_date"
    t.text "notes"
    t.date "next_follow_up_date"
    t.index ["comparison_id"], name: "index_tracking_on_comparison_id"
    t.index ["cover_letter_id"], name: "index_tracking_on_cover_letter_id"
    t.index ["job_listing_id"], name: "index_tracking_on_job_listing_id"
    t.index ["resume_id"], name: "index_tracking_on_resume_id"
  end

  add_foreign_key "comparisons", "job_listings"
  add_foreign_key "comparisons", "resumes"
  add_foreign_key "tracking", "comparisons"
  add_foreign_key "tracking", "cover_table", column: "cover_letter_id"
  add_foreign_key "tracking", "job_listings"
  add_foreign_key "tracking", "resumes"
end
