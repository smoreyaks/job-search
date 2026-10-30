module Domain
  # Plain-Ruby cover letter entity. Mirrors Resume but without extracted_text.
  CoverLetter = Data.define(
    :id, :file_name, :date_uploaded, :version_note, :file_path, :archived_at
  ) do
    def initialize(file_name:, file_path:, id: nil, date_uploaded: nil,
                   version_note: "N/A", archived_at: nil)
      super
    end

    def archived? = !archived_at.nil?
  end
end
