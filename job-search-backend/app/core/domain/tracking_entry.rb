module Domain
  # Plain-Ruby tracking entry. Created on Save All; represents the intent to
  # apply (not confirmation of submitting, which the `applied` flag tracks).
  TrackingEntry = Data.define(
    :id, :job_listing_id, :resume_id, :comparison_id, :cover_letter_id,
    :applied, :date_applied, :response_received, :follow_up_needed,
    :interview_date, :notes, :next_follow_up_date
  ) do
    def initialize(job_listing_id:, resume_id:, comparison_id:, cover_letter_id:,
                   id: nil, applied: false, date_applied: nil,
                   response_received: false, follow_up_needed: false,
                   interview_date: nil, notes: nil, next_follow_up_date: nil)
      super
    end
  end
end
