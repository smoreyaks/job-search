module UseCases
  # Refresh button (POST /jobs/refreshListings, Tracking page). Asks the job
  # source for the current expiry of every saved listing that has a source job
  # id, stores it, and applies Domain::JoeCheck.refresh. Costs one JSearch
  # request per listing checked, so it only runs when the user asks.
  #
  # Besides the manual mark-as-dead toggle, this is the only thing that changes
  # a listing's stored joe_status: fresh JSearch data is the source of truth,
  # so an employer who extends a listing's expiry brings it back to green, a
  # manually dead listing included (rules revised 23 Oct).
  #
  # A listing the source no longer returns is left unchanged: dropping out of
  # JSearch's results isn't proof either way. Listings saved before job ids
  # were stored are skipped.
  class RefreshListings
    def initialize(repository:, expiry_source:, clock: -> { Time.current })
      @repository = repository
      @expiry_source = expiry_source
      @clock = clock
    end

    # Returns { listings: all saved listings after the refresh, checked: count asked about }.
    def call
      listings = @repository.all
      checkable = listings.select { |l| l.jsearch_job_id.present? }
      expirations = @expiry_source.expirations(job_ids: checkable.map(&:jsearch_job_id))

      now = @clock.call
      refreshed = checkable.map do |listing|
        Domain::JoeCheck.refresh(listing, expirations[listing.jsearch_job_id], now: now)
      end
      @repository.refresh_all(refreshed)

      { listings: @repository.all, checked: checkable.size }
    end
  end
end
