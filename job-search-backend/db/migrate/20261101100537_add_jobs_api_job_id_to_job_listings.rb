# Keeps the Jobs API's (jobs-api14, LinkedIn) own job id beside JSearch's, so a
# saved job can be re-asked about through the API it came from. Nullable: rows
# saved from JSearch, and rows saved before this, have none.
class AddJobsApiJobIdToJobListings < ActiveRecord::Migration[8.1]
  def change
    add_column :job_listings, :jobs_api_job_id, :string
    add_index :job_listings, :jobs_api_job_id
  end
end
