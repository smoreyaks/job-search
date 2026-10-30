module UseCases
  # The real write behind Save All: commits the Compare result and a tracking
  # row together in one all-or-nothing transaction (so a failed tracking write
  # can't leave an orphaned comparisons row). Returns both new entities.
  class SaveApplication
    def initialize(comparisons:, tracking:, unit_of_work:)
      @comparisons = comparisons
      @tracking = tracking
      @unit_of_work = unit_of_work
    end

    def call(resume_id:, job_listing_id:, cover_letter_id:, match_score:, resume_suggestions:)
      @unit_of_work.transaction do
        comparison = @comparisons.create(
          resume_id: resume_id,
          job_listing_id: job_listing_id,
          match_score: match_score,
          resume_suggestions: resume_suggestions
        )

        tracking = @tracking.create(
          job_listing_id: job_listing_id,
          resume_id: resume_id,
          comparison_id: comparison.id,
          cover_letter_id: cover_letter_id
        )

        { comparison: comparison, tracking: tracking }
      end
    end
  end
end
