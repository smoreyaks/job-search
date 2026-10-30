class Comparison < ApplicationRecord
  belongs_to :resume
  belongs_to :job_listing

  # comparison_datetime is DB-defaulted (CURRENT_TIMESTAMP), so it is not
  # validated for presence (it is nil in memory until the insert runs).
  validates :match_score, presence: true
end
