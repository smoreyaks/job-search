module UseCases
  # Validates search input and delegates to the job source the user picked
  # (the Search page's API selector). Returns that port's job_listing-shaped
  # results unchanged.
  class SearchJobs
    ALLOWED_COUNTS = [1, 10, 30, 50, 100].freeze
    JOB_TYPES = %w[full-time part-time casual contract].freeze
    DEFAULT_COUNT = 10
    DEFAULT_SOURCE = "jsearch".freeze
    # The Search page's country selector. Each adapter turns the code into its
    # own filter (JSearch's country param, the Jobs API's location).
    COUNTRIES = %w[au us].freeze
    DEFAULT_COUNTRY = "au".freeze

    # job_sources: Hash of source name => JobSourcePort, e.g. "jsearch", "jobs_api".
    def initialize(job_sources:)
      @job_sources = job_sources
    end

    def call(keyword:, location: nil, remote: false, job_type: nil, count: DEFAULT_COUNT, source: DEFAULT_SOURCE,
             country: DEFAULT_COUNTRY)
      keyword = keyword.to_s.strip
      raise Errors::ValidationFailed, "keyword is required" if keyword.empty?

      if job_type && !JOB_TYPES.include?(job_type)
        raise Errors::ValidationFailed, "invalid job_type: #{job_type}"
      end

      country = country.to_s.downcase
      unless COUNTRIES.include?(country)
        raise Errors::ValidationFailed, "invalid country: #{country} (expected #{COUNTRIES.join(' or ')})"
      end

      job_source = @job_sources[source.to_s]
      if job_source.nil?
        raise Errors::ValidationFailed, "invalid source: #{source} (expected #{@job_sources.keys.join(' or ')})"
      end

      job_source.search(
        keyword: keyword,
        location: location,
        remote: !!remote,
        job_type: job_type,
        count: ALLOWED_COUNTS.include?(count) ? count : DEFAULT_COUNT,
        country: country
      )
    end
  end
end
