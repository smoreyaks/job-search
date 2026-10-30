module Domain
  # Result of running Compare: a match score plus the written analysis.
  # Produced as pure compute (no id/timestamp); gains id, resume_id,
  # job_listing_id and comparison_datetime only once persisted via Save All.
  ComparisonResult = Data.define(
    :id, :resume_id, :job_listing_id, :match_score, :resume_suggestions,
    :comparison_datetime
  ) do
    def initialize(match_score:, resume_suggestions: nil, id: nil,
                   resume_id: nil, job_listing_id: nil, comparison_datetime: nil)
      super
    end
  end
end
