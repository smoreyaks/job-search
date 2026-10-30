module ResumeRepositoryPort
  # Returns all non-archived resume entities, most recent first.
  def all
    raise NotImplementedError, "#{self.class}#all not implemented"
  end

  # Creates and returns a new resume entity.
  # file_name: String, file_path: String, version_note: String,
  # extracted_text: String (from pdf.js, may be nil)
  def create(file_name:, file_path:, version_note:, extracted_text: nil)
    raise NotImplementedError, "#{self.class}#create not implemented"
  end

  # Returns the resume entity with this id. Raises Errors::NotFound if none.
  def find(id)
    raise NotImplementedError, "#{self.class}#find not implemented"
  end
end
