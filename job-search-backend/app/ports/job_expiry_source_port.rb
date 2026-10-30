module JobExpirySourcePort
  # Asks the job source for the current expiry of already-saved jobs.
  # job_ids: Array of the source's own job ids.
  # Returns a Hash of job_id => expiry (Time, or nil if the source gives none).
  # Ids the source no longer returns are left out of the hash.
  def expirations(job_ids:)
    raise NotImplementedError, "#{self.class}#expirations not implemented"
  end
end
