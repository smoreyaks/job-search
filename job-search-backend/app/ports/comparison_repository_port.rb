module ComparisonRepositoryPort
  # Creates and returns a new comparison entity.
  # resume_id: Integer, job_listing_id: Integer,
  # match_score: Numeric, resume_suggestions: String
  def create(resume_id:, job_listing_id:, match_score:, resume_suggestions:)
    raise NotImplementedError, "#{self.class}#create not implemented"
  end
end
