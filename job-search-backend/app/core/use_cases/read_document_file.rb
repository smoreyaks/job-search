module UseCases
  # Returns a stored resume's or cover letter's PDF for the Edit page viewer.
  # Fetched on demand when one is opened, never on app load, so app load only
  # carries the lightweight rows (metadata and extracted text).
  #
  # Returns { file_name:, bytes: }.
  class ReadDocumentFile
    def initialize(documents:, file_storage:, config:)
      @documents = documents
      @file_storage = file_storage
      @config = config
    end

    def call(id:)
      document = @documents.find(id)
      bytes = @file_storage.read(file_path: document.file_path, directory: @config.current.local_app_data)
      { file_name: document.file_name, bytes: bytes }
    end
  end
end
