module JobSourcePort
  # Returns an array of job_listing-shaped hashes from the external job board API.
  # keyword: String, location: String, remote: Boolean,
  # job_type: String (full-time/part-time/contract/casual), count: Integer,
  # country: String ISO code ("au"/"us"), nil for the adapter's default
  def search(keyword:, location:, remote:, job_type:, count:, country: nil)
    raise NotImplementedError, "#{self.class}#search not implemented"
  end
end
