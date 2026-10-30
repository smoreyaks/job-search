class Config < ApplicationRecord
  self.table_name = "config"

  validates :local_app_data, :delimiter, presence: true
end
