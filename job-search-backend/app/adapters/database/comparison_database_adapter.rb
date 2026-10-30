# ActiveRecord-backed implementation of ComparisonRepositoryPort.
# Maps between the Comparison AR model and the Domain::ComparisonResult entity.
#
# No own transaction: create is called inside the Save All transaction (the
# SaveApplication use case wraps this and the tracking write via UnitOfWorkPort),
# so a bare insert is correct here.
class ComparisonDatabaseAdapter
  include ComparisonRepositoryPort

  def create(resume_id:, job_listing_id:, match_score:, resume_suggestions:)
    record = Comparison.create!(
      resume_id: resume_id,
      job_listing_id: job_listing_id,
      match_score: match_score,
      resume_suggestions: resume_suggestions
    ).reload # reload picks up the DB-defaulted comparison_datetime
    to_entity(record)
  end

  private

  MEMBERS = Domain::ComparisonResult.members.freeze

  def to_entity(record)
    Domain::ComparisonResult.new(**record.attributes.symbolize_keys.slice(*MEMBERS))
  end
end
