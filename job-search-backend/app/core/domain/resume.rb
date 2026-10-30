module Domain
  # Plain-Ruby resume entity. extracted_text comes from pdf.js at upload time.
  Resume = Data.define(
    :id, :file_name, :date_uploaded, :version_note, :file_path,
    :extracted_text, :archived_at
  ) do
    def initialize(file_name:, file_path:, id: nil, date_uploaded: nil,
                   version_note: "N/A", extracted_text: nil, archived_at: nil)
      super
    end

    def archived? = !archived_at.nil?
  end
end
