class JobsController < ApplicationController
  LISTING_KEYS = Domain::JobListing.members

  # GET /jobs/search  (source: "jsearch" or "jobs_api", default jsearch)
  def search
    results = Container.search_jobs.call(
      source: params[:source].presence || UseCases::SearchJobs::DEFAULT_SOURCE,
      keyword: params[:keyword],
      location: params[:location],
      remote: ActiveModel::Type::Boolean.new.cast(params[:remote]),
      job_type: params[:job_type].presence,
      count: params[:count].present? ? params[:count].to_i : 10
    )
    render json: results.map { |r| r.respond_to?(:to_h) ? r.to_h : r }
  end

  # POST /jobs/saveAll
  def save_all
    listings = listing_params.map { |attrs| build_listing(attrs) }
    result = Container.save_job_listings.call(listings: listings)

    render json: {
      saved: result[:saved].map(&:to_h),
      warnings: result[:warnings].map do |warning|
        { candidate_url: warning[:candidate_url], likely_match: warning[:likely_match].to_h }
      end
    }, status: :created
  end

  # GET /jobs/savedList
  def saved_list
    render_collection(Container.list_job_listings.call)
  end

  # POST /jobs/refreshListings  (Tracking page refresh button; 1 request per listing checked,
  # through the API each listing came from)
  def refresh_listings
    result = Container.refresh_listings.call
    render json: { listings: result[:listings].map(&:to_h), checked: result[:checked] }
  end

  private

  def listing_params
    params.permit(listings: LISTING_KEYS).fetch(:listings, [])
  end

  def build_listing(attrs)
    data = attrs.to_h.symbolize_keys
    data[:job_posted_date] = parse_date(data[:job_posted_date]) if data.key?(:job_posted_date)
    Domain::JobListing.new(**data)
  rescue ArgumentError => e
    raise Errors::ValidationFailed, "invalid job listing: #{e.message}"
  end

  # JSON carries dates as strings; parse into a Date so the domain (duplicate
  # detection) works with real date types, not strings.
  def parse_date(value)
    return value if value.is_a?(Date) || value.nil?

    Date.iso8601(value.to_s)
  rescue ArgumentError
    raise Errors::ValidationFailed, "invalid job_posted_date: #{value.inspect}"
  end
end
