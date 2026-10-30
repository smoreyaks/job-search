class Resume < ApplicationRecord
  validates :file_name, :file_path, presence: true

  scope :not_archived, -> { where(archived_at: nil) }
  scope :most_recent_first, -> { order(date_uploaded: :desc, id: :desc) }
end
