# Keeps what the Joe check needs from JSearch: its job_id (to re-ask JSearch
# about a saved job) and job_offer_expiration_datetime_utc (to recheck expiry
# on app load with no API call). Both nullable: rows saved before this, and
# JSearch results without an expiry, simply have none.
class AddJSearchFieldsToJobListings < ActiveRecord::Migration[8.1]
  def change
    add_column :job_listings, :jsearch_job_id, :string
    add_column :job_listings, :job_offer_expires_at, :datetime
    add_index :job_listings, :jsearch_job_id
  end
end
