module UseCases
  # Saves a batch of flagged job listings. Runs duplicate detection first as a
  # soft warning (never blocks the save), then persists all listings atomically.
  #
  # Returns { saved: [Domain::JobListing], warnings: [Hash] } where each warning
  # is { candidate_url:, likely_match: Domain::JobListing }.
  class SaveJobListings
    def initialize(repository:, duplicate_detector: Domain::DuplicateDetector.new)
      @repository = repository
      @duplicate_detector = duplicate_detector
    end

    def call(listings:)
      raise Errors::ValidationFailed, "no listings provided" if listings.nil? || listings.empty?

      warnings = detect_warnings(listings)
      saved = @repository.save_all(listings)
      { saved: saved, warnings: warnings }
    end

    private

    def detect_warnings(listings)
      existing = @repository.find_candidates(listings.first)
      listings.filter_map do |listing|
        match = @duplicate_detector.find_duplicate(listing, existing)
        { candidate_url: listing.url, likely_match: match } if match
      end
    end
  end
end
