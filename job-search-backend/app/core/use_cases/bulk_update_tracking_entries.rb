module UseCases
  # Save all: updates every changed tracking row in one transaction. Reuses the
  # same row-level sanitizer, and skips rows that carry no editable changes.
  #
  # Like row save, a change may carry the mark-as-dead toggle (joe_status 1 or
  # 2), written to that row's job listing inside the same transaction. A row
  # whose only change is the toggle still counts as changed, so it comes back
  # in the result (Angular clears its dirty state from what's returned).
  class BulkUpdateTrackingEntries
    def initialize(repository:, job_listings:, unit_of_work:, sanitizer: Domain::TrackingFieldSanitizer.new)
      @repository = repository
      @job_listings = job_listings
      @unit_of_work = unit_of_work
      @sanitizer = sanitizer
    end

    def call(changes:)
      return [] if changes.nil? || changes.empty?

      sanitized = changes.filter_map do |change|
        id = change[:id] || change["id"]
        raw = change[:changed_fields] || change["changed_fields"] || {}
        fields = @sanitizer.sanitize(raw)
        joe_status = Domain::JoeCheck.manual_value(raw)
        { id: id, changed_fields: fields, joe_status: joe_status } unless fields.empty? && joe_status.nil?
      end

      return [] if sanitized.empty?

      @unit_of_work.transaction do
        with_fields = sanitized.reject { |change| change[:changed_fields].empty? }
        updated = @repository.update_many(changes: with_fields.map { |c| c.slice(:id, :changed_fields) })
                             .to_h { |entry| [entry.id, entry] }

        sanitized.map do |change|
          entry = updated[change[:id]] || @repository.find(change[:id])
          @job_listings.set_joe_status(id: entry.job_listing_id, joe_status: change[:joe_status]) if change[:joe_status]
          entry
        end
      end
    end
  end
end
