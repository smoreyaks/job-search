module JobListingRepositoryPort
  # Returns all non-archived job listing entities.
  def all
    raise NotImplementedError, "#{self.class}#all not implemented"
  end

  # Saves an array of job listing attribute hashes in one transaction.
  # Returns the saved entities.
  def save_all(listings)
    raise NotImplementedError, "#{self.class}#save_all not implemented"
  end

  # Returns existing rows to compare against for duplicate detection.
  # listing is a hash of job listing attributes.
  def find_candidates(listing)
    raise NotImplementedError, "#{self.class}#find_candidates not implemented"
  end

  # Re-saves refreshed listings as updates to existing rows, joe_status and all
  # mapped fields included. Never inserts new rows. The caller applies the Joe
  # status rules (Domain::JoeCheck.refresh) before calling this.
  def refresh_all(listings)
    raise NotImplementedError, "#{self.class}#refresh_all not implemented"
  end

  # Sets one listing's joe_status (the manual mark-as-dead toggle), the only way
  # a row gets into state 2.
  def set_joe_status(id:, joe_status:)
    raise NotImplementedError, "#{self.class}#set_joe_status not implemented"
  end
end
