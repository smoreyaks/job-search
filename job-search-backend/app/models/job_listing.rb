class JobListing < ApplicationRecord
  # Plain string columns (not AR enums) so attributes expose the canonical DB
  # values ("full-time", "on-site") directly, giving a clean 1:1 map to the
  # Domain::JobListing entity. The enum constraint is enforced via validation.
  # board_source is free text: the publisher name exactly as JSearch reports it.
  EMPLOYMENT_TYPES = %w[full-time part-time contract casual].freeze
  REMOTE_TYPES     = %w[remote hybrid on-site].freeze
  STATUSES         = %w[active closed].freeze

  validates :company, :job_title, :job_posted_date, presence: true
  validates :job_description, :url, presence: true
  validates :board_source,    presence: true
  validates :employment_type, inclusion: { in: EMPLOYMENT_TYPES }
  validates :remote_type,     inclusion: { in: REMOTE_TYPES }
  validates :status,          inclusion: { in: STATUSES }

  scope :not_archived, -> { where(archived_at: nil) }
end
