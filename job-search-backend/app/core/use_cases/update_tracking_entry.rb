module UseCases
  # Row save: updates one tracking row with only its changed, editable fields.
  # Whitelisting + date validation live in the shared sanitizer.
  #
  # The change set may also carry the mark-as-dead toggle (joe_status 1 or 2).
  # joe_status lives on the row's job listing, not on tracking, so it's written
  # there, in the same transaction as the tracking fields (PRD: the toggle rides
  # the existing Tracking save paths, no route of its own).
  class UpdateTrackingEntry
    def initialize(repository:, job_listings:, unit_of_work:, sanitizer: Domain::TrackingFieldSanitizer.new)
      @repository = repository
      @job_listings = job_listings
      @unit_of_work = unit_of_work
      @sanitizer = sanitizer
    end

    def call(id:, changed_fields:)
      raise Errors::ValidationFailed, "id is required" if id.nil?

      fields = @sanitizer.sanitize(changed_fields)
      joe_status = Domain::JoeCheck.manual_value(changed_fields)
      raise Errors::ValidationFailed, "no editable fields provided" if fields.empty? && joe_status.nil?

      @unit_of_work.transaction do
        entry = fields.empty? ? @repository.find(id) : @repository.update(id: id, changed_fields: fields)
        @job_listings.set_joe_status(id: entry.job_listing_id, joe_status: joe_status) if joe_status
        entry
      end
    end
  end
end
