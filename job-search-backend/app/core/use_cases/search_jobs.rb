module UseCases
  # Validates search input and delegates to the job source port. Returns the
  # port's job_listing-shaped results unchanged.
  class SearchJobs
    ALLOWED_COUNTS = [1, 10, 30, 50, 100].freeze
    JOB_TYPES = %w[full-time part-time casual contract].freeze
    DEFAULT_COUNT = 10

    def initialize(job_source:)
      @job_source = job_source
    end

    def call(keyword:, location: nil, remote: false, job_type: nil, count: DEFAULT_COUNT)
      keyword = keyword.to_s.strip
      raise Errors::ValidationFailed, "keyword is required" if keyword.empty?

      if job_type && !JOB_TYPES.include?(job_type)
        raise Errors::ValidationFailed, "invalid job_type: #{job_type}"
      end

      @job_source.search(
        keyword: keyword,
        location: location,
        remote: !!remote,
        job_type: job_type,
        count: ALLOWED_COUNTS.include?(count) ? count : DEFAULT_COUNT
      )
    end
  end
end
