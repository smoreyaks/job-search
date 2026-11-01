module JobDetailsSourcePort
  # Fetches the full details of jobs the source's search only summarised.
  # job_ids: Array of the source's own job ids.
  # Returns a Hash of job_id => { job_description:, employment_type: }.
  # Ids the source no longer returns are left out of the hash.
  def details(job_ids:)
    raise NotImplementedError, "#{self.class}#details not implemented"
  end
end
