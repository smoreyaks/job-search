# ActiveRecord-backed implementation of TrackingRepositoryPort.
# Maps between the Tracking AR model (table tracking) and the
# Domain::TrackingEntry entity.
class TrackingDatabaseAdapter
  include TrackingRepositoryPort

  # All tracking entries, newest first (tracking has no timestamp column, so id
  # order is the stand-in for creation order).
  def all
    Tracking.order(id: :desc).map { |record| to_entity(record) }
  end

  def find(id)
    to_entity(Tracking.find(id))
  end

  # Creates a tracking entry (called from Save All on the Edit page).
  def create(job_listing_id:, resume_id:, comparison_id:, cover_letter_id:)
    record = Tracking.create!(
      job_listing_id: job_listing_id,
      resume_id: resume_id,
      comparison_id: comparison_id,
      cover_letter_id: cover_letter_id
    )
    to_entity(record)
  end

  # Updates one row with the already-whitelisted changed fields.
  def update(id:, changed_fields:)
    record = Tracking.find(id)
    record.update!(changed_fields)
    to_entity(record)
  end

  # Updates many rows in one transaction. changes: array of
  # { id:, changed_fields: } hashes (symbol or string keys).
  def update_many(changes:)
    ActiveRecord::Base.transaction do
      changes.map do |change|
        id = change[:id] || change["id"]
        fields = change[:changed_fields] || change["changed_fields"]
        record = Tracking.find(id)
        record.update!(fields)
        to_entity(record)
      end
    end
  end

  private

  MEMBERS = Domain::TrackingEntry.members.freeze

  def to_entity(record)
    Domain::TrackingEntry.new(**record.attributes.symbolize_keys.slice(*MEMBERS))
  end
end
