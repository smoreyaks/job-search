class Tracking < ApplicationRecord
  self.table_name = "tracking"

  belongs_to :job_listing
  belongs_to :resume
  belongs_to :comparison
  belongs_to :cover_letter, foreign_key: :cover_letter_id, class_name: "CoverLetter"
end
