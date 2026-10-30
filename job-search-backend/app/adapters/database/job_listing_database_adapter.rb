# ActiveRecord-backed implementation of JobListingRepositoryPort.
# Maps between the JobListing AR model and the Domain::JobListing entity.
# Core code only ever sees entities; ActiveRecord stays behind this adapter.
class JobListingDatabaseAdapter
  include JobListingRepositoryPort

  # All non-archived listings, newest first. id breaks ties because a bulk
  # save_all gives every row the same date_saved (Postgres CURRENT_TIMESTAMP is
  # the transaction-start time), so date_saved alone is not a stable order.
  def all
    JobListing.not_archived.order(date_saved: :desc, id: :desc).map { |record| to_entity(record) }
  end

  # Persists an array of Domain::JobListing entities in one transaction.
  # Returns the saved entities (now carrying ids and DB-defaulted fields).
  def save_all(listings)
    records = ActiveRecord::Base.transaction do
      # reload picks up DB-computed defaults (date_saved) omitted from the insert
      listings.map { |entity| JobListing.create!(to_attributes(entity)).reload }
    end
    records.map { |record| to_entity(record) }
  end

  # Returns non-archived listings as candidates for the core DuplicateDetector
  # to fuzzy-match against. Matching logic (Levenshtein on company/job_title,
  # the ±3-day date window, etc.) lives in core, so this stays a dumb row source.
  def find_candidates(_listing)
    JobListing.not_archived.map { |record| to_entity(record) }
  end

  # Updates existing rows from refreshed listings (never inserts). The refresh
  # use case has already applied the Joe status rules, the latch on manually
  # dead rows included, so each listing is written as given.
  def refresh_all(listings)
    ActiveRecord::Base.transaction do
      listings.filter_map do |entity|
        record = JobListing.find_by(id: entity.id)
        next if record.nil?

        record.update!(to_attributes(entity).except(:date_saved, :archived_at))
        to_entity(record)
      end
    end
  end

  def set_joe_status(id:, joe_status:)
    record = JobListing.find(id)
    record.update!(joe_status: joe_status)
    to_entity(record)
  end

  private

  MEMBERS = Domain::JobListing.members.freeze

  # AR record -> Domain::JobListing. slice guards against future extra columns.
  def to_entity(record)
    Domain::JobListing.new(**record.attributes.symbolize_keys.slice(*MEMBERS))
  end

  # Domain::JobListing -> attributes hash for AR. Drops id and nils so DB
  # defaults (date_saved, status, joe_status) and NULLs apply on create.
  def to_attributes(entity)
    entity.to_h.except(:id).compact
  end
end
