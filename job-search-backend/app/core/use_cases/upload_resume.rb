module UseCases
  # Validates the upload is a PDF, writes the bytes to localAppData via the file
  # storage port, and records the resume row with the pdf.js-extracted text.
  # No file cap: the "20" in the PRD is a UI render limit, not a storage limit.
  class UploadResume
    def initialize(resumes:, file_storage:, config:)
      @resumes = resumes
      @file_storage = file_storage
      @config = config
    end

    def call(file_name:, bytes:, version_note: "N/A", extracted_text: nil)
      Pdf.validate!(file_name, bytes)

      directory = @config.current.local_app_data
      file_path = @file_storage.store(file_name: file_name, bytes: bytes, directory: directory)

      @resumes.create(
        file_name: file_name,
        file_path: file_path,
        version_note: version_note.to_s.empty? ? "N/A" : version_note,
        extracted_text: extracted_text
      )
    end
  end
end
