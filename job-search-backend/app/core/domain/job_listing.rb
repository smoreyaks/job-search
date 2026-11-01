module Domain
  # Plain-Ruby job listing entity. No ActiveRecord. Database adapters map
  # between the JobListing AR model and this value object.
  JobListing = Data.define(
    :id, :board_source, :company, :job_title, :location, :job_posted_date,
    :employment_type, :remote_type, :salary_range, :hourly_rate,
    :job_description, :url, :application_url, :posted_by,
    :poster_contact_number, :poster_email, :date_saved, :status,
    :joe_status, :archived_at, :jsearch_job_id, :job_offer_expires_at,
    :jobs_api_job_id
  ) do
    def initialize(board_source:, company:, job_title:, job_posted_date:,
                   employment_type:, job_description:, url:,
                   id: nil, location: nil, remote_type: "on-site",
                   salary_range: "N/A", hourly_rate: "N/A",
                   application_url: "N/A", posted_by: "N/A",
                   poster_contact_number: "N/A", poster_email: "N/A",
                   date_saved: nil, status: "active", joe_status: 0,
                   archived_at: nil, jsearch_job_id: nil, job_offer_expires_at: nil,
                   jobs_api_job_id: nil)
      super
    end

    def archived?            = !archived_at.nil?
    def passes_joe_check?    = joe_status.zero?
    def manually_marked_dead? = joe_status == 2
  end
end
