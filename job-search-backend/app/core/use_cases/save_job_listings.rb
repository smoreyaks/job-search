module UseCases
  # Saves a batch of flagged job listings. Fills in the description of any
  # Jobs API listing first (its search only returns summaries), then runs
  # duplicate detection as a soft warning (never blocks the save), then
  # persists all listings atomically.
  #
  # Returns { saved: [Domain::JobListing], warnings: [Hash] } where each warning
  # is { candidate_url:, likely_match: Domain::JobListing }.
  class SaveJobListings
    # details_source: JobDetailsSourcePort for Jobs API listings (1 request per
    # listing that needs it). Without one, listings are saved as given.
    def initialize(repository:, details_source: nil, duplicate_detector: Domain::DuplicateDetector.new)
      @repository = repository
      @details_source = details_source
      @duplicate_detector = duplicate_detector
    end

    def call(listings:)
      raise Errors::ValidationFailed, "no listings provided" if listings.nil? || listings.empty?

      listings = fill_in_details(listings)
      warnings = detect_warnings(listings)
      saved = @repository.save_all(listings)
      { saved: saved, warnings: warnings }
    end

    private

    def fill_in_details(listings)
      missing = listings.select { |l| l.jobs_api_job_id.present? && l.job_description.blank? }
      return listings if missing.empty? || @details_source.nil?

      details = @details_source.details(job_ids: missing.map(&:jobs_api_job_id))
      listings.map do |listing|
        next listing unless missing.include?(listing)

        found = details[listing.jobs_api_job_id]
        if found.nil? || found[:job_description].blank?
          raise Errors::ExternalServiceFailed,
                "Couldn't get the description for \"#{listing.job_title}\" at #{listing.company}; it may have been taken down"
        end

        listing.with(**found)
      end
    end

    def detect_warnings(listings)
      existing = @repository.find_candidates(listings.first)
      listings.filter_map do |listing|
        match = @duplicate_detector.find_duplicate(listing, existing)
        { candidate_url: listing.url, likely_match: match } if match
      end
    end
  end
end
