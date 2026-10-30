module TrackingRepositoryPort
  # Returns all tracking entities.
  def all
    raise NotImplementedError, "#{self.class}#all not implemented"
  end

  # Returns one tracking entity by id (raises if it doesn't exist).
  def find(id)
    raise NotImplementedError, "#{self.class}#find not implemented"
  end

  # Creates a new tracking entry (called from Save All on the Edit page).
  # job_listing_id:, resume_id:, comparison_id:, cover_letter_id: Integer
  def create(job_listing_id:, resume_id:, comparison_id:, cover_letter_id:)
    raise NotImplementedError, "#{self.class}#create not implemented"
  end

  # Updates a single tracking row with only the changed fields.
  # id: Integer, changed_fields: Hash
  def update(id:, changed_fields:)
    raise NotImplementedError, "#{self.class}#update not implemented"
  end

  # Updates multiple tracking rows in one transaction.
  # changes: Array of { id:, changed_fields: } hashes
  def update_many(changes:)
    raise NotImplementedError, "#{self.class}#update_many not implemented"
  end
end
