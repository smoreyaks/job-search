require "net/http"
require "json"

# Fulfills JobSourcePort against the Jobs API (jobs-api14 on RapidAPI, LinkedIn
# listings). Runs in parallel with JSearchAdapter; the user picks which one a
# search uses. Added 1 Nov 2026 because JSearch returns no Australian jobs.
#
# Search returns summaries only (no description, salary or employment type) at
# 1 request per 10 jobs. The full description costs 1 more request per job, so
# it's fetched on save through JobDetailsSourcePort, not with every search.
# Also fulfills JobExpirySourcePort: the API has no expiry date, but
# acceptingApplications false means the job has closed.
#
# Uses the same RapidAPI key as JSearch (one key per RapidAPI account). Raises
# ExternalServiceFailed on a missing key, rate limit, API error or transport error.
class JobsApiAdapter
  include JobSourcePort
  include JobDetailsSourcePort
  include JobExpirySourcePort

  HOST = "jobs-api14.p.rapidapi.com".freeze
  SEARCH_ENDPOINT = "v2/linkedin/search".freeze
  GET_ENDPOINT = "v2/linkedin/get".freeze
  RESULTS_PER_PAGE = 10
  # Every page is a billed request, so cap a single search well below the plan.
  MAX_PAGES = 10
  BOARD_SOURCE = "LinkedIn".freeze
  # A blank location would search worldwide; this app targets Australia.
  # Overridable via JOBS_API_DEFAULT_LOCATION. Used when a search gives no country.
  DEFAULT_LOCATION = "Australia".freeze

  # The API filters by free-text location only, so a search's country code
  # becomes a country name: the whole location when none is typed, otherwise
  # appended ("Sydney" -> "Sydney, Australia") so a same-named place elsewhere
  # isn't matched.
  COUNTRY_NAMES = {
    "au" => "Australia",
    "us" => "United States",
  }.freeze

  # Our employment enum -> the API's employmentTypes filter.
  EMPLOYMENT_FILTER = {
    "full-time" => "fulltime",
    "part-time" => "parttime",
    "contract" => "contractor",
    "casual" => "temporary",
  }.freeze

  # LinkedIn's employmentType label (job details) -> our employment enum.
  EMPLOYMENT_FROM_LINKEDIN = {
    "full-time" => "full-time",
    "part-time" => "part-time",
    "contract" => "contract",
    "temporary" => "casual",
    "internship" => "casual",
  }.freeze

  def initialize(api_key: ENV["RAPIDAPI_KEY"])
    @api_key = api_key
  end

  def search(keyword:, location:, remote:, job_type:, count:, country: nil)
    require_api_key!

    params = build_params(keyword, location, remote, job_type, country)
    jobs = []
    pages_for(count).times do
      json = request(SEARCH_ENDPOINT, params)
      jobs.concat(Array(json["data"]))
      token = json.dig("meta", "nextToken")
      break if jobs.size >= count || token.blank?

      # The API's paging contract: a follow-up page sends the token alone.
      params = { "token" => token }
    end

    jobs.first(count).map { |raw| map_listing(raw, remote: remote, job_type: job_type) }
  end

  def details(job_ids:)
    each_job(job_ids).transform_values do |raw|
      {
        job_description: raw["description"].to_s,
        employment_type: EMPLOYMENT_FROM_LINKEDIN[raw["employmentType"].to_s.downcase],
      }.compact
    end
  end

  # A job that's stopped accepting applications counts as expired now; one
  # still accepting gives no date, which leaves the listing as it was.
  def expirations(job_ids:)
    each_job(job_ids).transform_values do |raw|
      raw["acceptingApplications"] == false ? Time.current : nil
    end
  end

  private

  def require_api_key!
    return unless @api_key.to_s.strip.empty?

    raise Errors::ExternalServiceFailed, "Jobs API key not set (RAPIDAPI_KEY)"
  end

  # One get request per id (the API has no batch lookup). Returns id => raw job;
  # an id the API reports an error for (a removed job) is left out.
  def each_job(job_ids)
    ids = job_ids.compact.uniq
    return {} if ids.empty?

    require_api_key!

    ids.each_with_object({}) do |id, result|
      json = request(GET_ENDPOINT, { "id" => id }, allow_api_error: true)
      raw = json["data"]
      result[id] = raw if raw.is_a?(Hash) && !json["hasError"]
    end
  end

  def build_params(keyword, location, remote, job_type, country)
    params = {
      "query" => keyword.to_s.strip,
      "location" => location_for_search(location, country),
    }
    params["workplaceTypes"] = "remote" if remote
    filter = EMPLOYMENT_FILTER[job_type]
    params["employmentTypes"] = filter if filter
    params
  end

  def location_for_search(location, country)
    location = location.to_s.strip
    country_name = COUNTRY_NAMES[country.to_s.downcase]
    return location.presence || default_location if country_name.nil?
    return country_name if location.empty?
    return location if location.downcase.include?(country_name.downcase)

    "#{location}, #{country_name}"
  end

  def default_location
    ENV.fetch("JOBS_API_DEFAULT_LOCATION", DEFAULT_LOCATION)
  end

  def pages_for(count)
    [[(count.to_f / RESULTS_PER_PAGE).ceil, 1].max, MAX_PAGES].min
  end

  def request(endpoint, params, allow_api_error: false)
    uri = URI("https://#{HOST}/#{endpoint}")
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request["X-RapidAPI-Key"] = @api_key
    request["X-RapidAPI-Host"] = HOST

    response = http.request(request)
    raise Errors::ExternalServiceFailed, "Jobs API rate limit reached (HTTP 429)" if response.code.to_i == 429
    unless response.is_a?(Net::HTTPSuccess)
      raise Errors::ExternalServiceFailed, "Jobs API request failed (HTTP #{response.code})"
    end

    json = JSON.parse(sanitize_json(response.body))
    if json["hasError"] && !allow_api_error
      raise Errors::ExternalServiceFailed, "Jobs API error: #{Array(json['errors']).join('; ')}"
    end

    json
  rescue Errors::ExternalServiceFailed
    raise
  rescue StandardError => e
    raise Errors::ExternalServiceFailed, "Jobs API request error: #{e.message}"
  end

  # Same guard as JSearchAdapter: drop unicode surrogate escapes (emoji) that
  # Ruby's strict JSON parser can reject.
  def sanitize_json(body)
    body.gsub(/\\u[dD][89a-fA-F][0-9a-fA-F]{2}/, "")
  end

  # Search results carry no description or employment type. The description is
  # left blank until save; the employment type is the filter used, if any.
  def map_listing(raw, remote:, job_type:)
    Domain::JobListing.new(
      board_source: BOARD_SOURCE,
      company: raw["companyName"].presence || "Private Advertiser",
      job_title: raw["title"].to_s,
      location: raw["location"].presence,
      job_posted_date: posted_date_for(raw),
      employment_type: EMPLOYMENT_FILTER.key?(job_type) ? job_type : "full-time",
      remote_type: remote ? "remote" : "on-site",
      job_description: "",
      url: raw["linkedinUrl"].to_s,
      application_url: raw["linkedinUrl"].presence || "N/A",
      jobs_api_job_id: raw["id"]&.to_s,
    )
  end

  def posted_date_for(raw)
    value = raw["datePosted"]
    value ? Date.parse(value) : Date.current
  rescue ArgumentError
    Date.current
  end
end
