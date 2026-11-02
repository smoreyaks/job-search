require "net/http"
require "json"

# Fulfills JobSourcePort against JSearch (RapidAPI). Joins keyword + location
# into JSearch's single `query`, maps the remote flag and job type to JSearch
# filters, fetches enough pages to cover the requested count, and reshapes each
# raw result into a Domain::JobListing. Also fulfills JobExpirySourcePort via
# the job-details endpoint. The API key comes from ENV (never committed).
# Raises ExternalServiceFailed on a missing key, rate limit, or transport error.
class JSearchAdapter
  include JobSourcePort
  include JobExpirySourcePort

  HOST = "jsearch.p.rapidapi.com".freeze
  ENDPOINT = "search-v2".freeze
  # job-details is unversioned (verified 20 Oct). It takes comma-separated ids
  # but still bills 1 request per id, so batching saves round trips, not quota.
  DETAILS_ENDPOINT = "job-details".freeze
  DETAILS_BATCH_SIZE = 20
  RESULTS_PER_PAGE = 10
  MAX_PAGES = 20
  # This app targets Australian job boards (Seek/Indeed/LinkedIn/Jora), so
  # default JSearch's country filter to AU. Overridable via JSEARCH_COUNTRY.
  # A search's own country (the Search page's selector) takes precedence;
  # the default still covers job-details lookups.
  DEFAULT_COUNTRY = "au".freeze

  # Our employment enum -> JSearch employment_types filter.
  EMPLOYMENT_FILTER = {
    "full-time" => "FULLTIME",
    "part-time" => "PARTTIME",
    "contract" => "CONTRACTOR",
    "casual" => "INTERN",
  }.freeze

  # JSearch job_employment_type -> our employment enum.
  EMPLOYMENT_FROM_JSEARCH = {
    "FULLTIME" => "full-time",
    "PARTTIME" => "part-time",
    "CONTRACTOR" => "contract",
    "INTERN" => "casual",
  }.freeze

  def initialize(api_key: ENV["RAPIDAPI_KEY"])
    @api_key = api_key
  end

  def search(keyword:, location:, remote:, job_type:, count:, country: nil)
    require_api_key!

    json = request(ENDPOINT, build_params(keyword, location, remote, job_type, count, country))
    # search-v2 nests the jobs at data.jobs (data is an object with jobs + cursor).
    Array(json.dig("data", "jobs")).first(count).map { |raw| map_listing(raw) }
  end

  def expirations(job_ids:)
    ids = job_ids.compact.uniq
    return {} if ids.empty?

    require_api_key!

    ids.each_slice(DETAILS_BATCH_SIZE).each_with_object({}) do |batch, result|
      params = { "job_id" => batch.join(","), "country" => country }
      # job-details returns data as a plain array of jobs.
      Array(request(DETAILS_ENDPOINT, params)["data"]).each do |raw|
        result[raw["job_id"]] = expires_at_for(raw)
      end
    end
  end

  private

  def require_api_key!
    return unless @api_key.to_s.strip.empty?

    raise Errors::ExternalServiceFailed, "JSearch API key not set (RAPIDAPI_KEY)"
  end

  def country
    ENV.fetch("JSEARCH_COUNTRY", DEFAULT_COUNTRY)
  end

  def build_params(keyword, location, remote, job_type, count, search_country)
    query = [keyword, location].map(&:to_s).map(&:strip).reject(&:empty?).join(" in ")
    params = {
      "query" => query,
      "num_pages" => pages_for(count),
      "country" => search_country.presence || country,
    }
    params["remote_jobs_only"] = "true" if remote
    filter = EMPLOYMENT_FILTER[job_type]
    params["employment_types"] = filter if filter
    params
  end

  def pages_for(count)
    [[(count.to_f / RESULTS_PER_PAGE).ceil, 1].max, MAX_PAGES].min
  end

  def request(endpoint, params)
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
    raise Errors::ExternalServiceFailed, "JSearch rate limit reached (HTTP 429)" if response.code.to_i == 429
    unless response.is_a?(Net::HTTPSuccess)
      raise Errors::ExternalServiceFailed, "JSearch request failed (HTTP #{response.code})"
    end

    JSON.parse(sanitize_json(response.body))
  rescue Errors::ExternalServiceFailed
    raise
  rescue StandardError => e
    raise Errors::ExternalServiceFailed, "JSearch request error: #{e.message}"
  end

  # JSearch returns unicode surrogate escapes (emoji in descriptions) that
  # Ruby's strict JSON parser rejects as "incomplete surrogate pair" (Python
  # tolerates them). Strip surrogate escapes before parsing — we don't need emoji.
  def sanitize_json(body)
    body.gsub(/\\u[dD][89a-fA-F][0-9a-fA-F]{2}/, "")
  end

  def map_listing(raw)
    Domain::JobListing.new(
      board_source: board_source_for(raw["job_publisher"]),
      company: raw["employer_name"].presence || "Private Advertiser",
      job_title: raw["job_title"].to_s,
      location: location_for(raw),
      job_posted_date: posted_date_for(raw),
      employment_type: EMPLOYMENT_FROM_JSEARCH[raw["job_employment_type"].to_s] || "full-time",
      remote_type: raw["job_is_remote"] ? "remote" : "on-site",
      salary_range: salary_for(raw),
      hourly_rate: "N/A",
      job_description: raw["job_description"].to_s,
      url: raw["job_apply_link"].presence || raw["job_google_link"].to_s,
      application_url: raw["job_apply_link"].presence || "N/A",
      jsearch_job_id: raw["job_id"],
      job_offer_expires_at: expires_at_for(raw),
    ).then { |listing| Domain::JoeCheck.apply(listing) }
  end

  # The job's real publisher, stored exactly as JSearch reports it ("LinkedIn",
  # "Glassdoor", "SEEK"...), whatever the site. The app never scrapes boards, so
  # there's no fixed list to map onto.
  UNKNOWN_PUBLISHER = "Unknown".freeze

  def board_source_for(publisher)
    publisher.to_s.strip.presence || UNKNOWN_PUBLISHER
  end

  def location_for(raw)
    [raw["job_city"], raw["job_state"], raw["job_country"]]
      .map(&:to_s).map(&:strip).reject(&:empty?).join(", ").presence
  end

  def posted_date_for(raw)
    value = raw["job_posted_at_datetime_utc"]
    value ? Date.parse(value) : Date.current
  rescue ArgumentError
    Date.current
  end

  def salary_for(raw)
    min = raw["job_min_salary"]
    max = raw["job_max_salary"]
    return "N/A" unless min || max

    currency = raw["job_salary_currency"]
    period = raw["job_salary_period"]
    "#{min || '?'}–#{max || '?'} #{currency} per #{period}".squeeze(" ").strip
  end

  def expires_at_for(raw)
    Domain::JoeCheck.parse(raw["job_offer_expiration_datetime_utc"])
  end
end
