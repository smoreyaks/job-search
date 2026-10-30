module UseCases
  # Mirrors UploadResume without extracted text: validates PDF, writes to
  # localAppData via the file storage port, records the cover_table row.
  class UploadCoverLetter
    def initialize(cover_letters:, file_storage:, config:)
      @cover_letters = cover_letters
      @file_storage = file_storage
      @config = config
    end

    def call(file_name:, bytes:, version_note: "N/A")
      Pdf.validate!(file_name, bytes)

      directory = @config.current.local_app_data
      file_path = @file_storage.store(file_name: file_name, bytes: bytes, directory: directory)

      @cover_letters.create(
        file_name: file_name,
        file_path: file_path,
        version_note: version_note.to_s.empty? ? "N/A" : version_note
      )
    end
  end
end
