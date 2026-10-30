module CoverLetterRepositoryPort
  # Returns all non-archived cover letter entities, most recent first.
  def all
    raise NotImplementedError, "#{self.class}#all not implemented"
  end

  # Creates and returns a new cover letter entity.
  # file_name: String, file_path: String, version_note: String
  def create(file_name:, file_path:, version_note:)
    raise NotImplementedError, "#{self.class}#create not implemented"
  end

  # Returns the cover letter entity with this id. Raises Errors::NotFound if none.
  def find(id)
    raise NotImplementedError, "#{self.class}#find not implemented"
  end
end
