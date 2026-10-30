module FileStoragePort
  # Writes the given bytes under file_name inside directory and returns the
  # stored file_path (relative to directory). Rails owns localAppData on disk;
  # Angular never touches the filesystem (PRD, Local save revised 16 Oct).
  def store(file_name:, bytes:, directory:)
    raise NotImplementedError, "#{self.class}#store not implemented"
  end

  # Returns the bytes of a file stored earlier (file_path relative to
  # directory). Raises Errors::NotFound when it's no longer on disk.
  def read(file_path:, directory:)
    raise NotImplementedError, "#{self.class}#read not implemented"
  end
end
