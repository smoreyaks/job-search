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
  #
  # Listings saved from the Jobs API (jobs_api_job_id) are asked about through
  # jobs_api_expiry_source instead, 1 request each. Each listing is checked
  # through the API it came from.
  class RefreshListings
    def initialize(repository:, expiry_source:, jobs_api_expiry_source: nil, clock: -> { Time.current })
      @repository = repository
      @expiry_source = expiry_source
      @jobs_api_expiry_source = jobs_api_expiry_source
      @clock = clock
    end

    # Returns { listings: all saved listings after the refresh, checked: count asked about }.
    def call
      listings = @repository.all
      now = @clock.call

      refreshed = refresh_through(@expiry_source, listings, :jsearch_job_id, now)
      if @jobs_api_expiry_source
        refreshed += refresh_through(@jobs_api_expiry_source, listings, :jobs_api_job_id, now)
      end
      @repository.refresh_all(refreshed)

      { listings: @repository.all, checked: refreshed.size }
    end

    private

    def refresh_through(source, listings, id_field, now)
      checkable = listings.select { |l| l.public_send(id_field).present? }
      return [] if checkable.empty?

      expirations = source.expirations(job_ids: checkable.map(&id_field))
      checkable.map do |listing|
        Domain::JoeCheck.refresh(listing, expirations[listing.public_send(id_field)], now: now)
      end
    end
  end
end
