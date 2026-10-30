require "rails_helper"

RSpec.describe JSearchAdapter do
  subject(:adapter) { described_class.new(api_key: "test-key") }

  def jsearch_body(jobs)
    # search-v2 shape: jobs nested under data.jobs
    { "status" => "OK", "data" => { "jobs" => jobs, "cursor" => nil } }.to_json
  end

  it "honors the JobSourcePort contract" do
    expect(adapter).to be_a(JobSourcePort)
  end

  it "raises a clear error when the API key is missing" do
    expect { described_class.new(api_key: nil).search(keyword: "ruby", location: nil, remote: false, job_type: nil, count: 10) }
      .to raise_error(Errors::ExternalServiceFailed, /RAPIDAPI_KEY/)
  end

  it "maps JSearch results into Domain::JobListing entities" do
    stub_request(:get, /jsearch\.p\.rapidapi\.com/).to_return(
      status: 200,
      body: jsearch_body([
        {
          "job_title" => "Ruby Developer",
          "employer_name" => "Acme",
          "job_publisher" => "LinkedIn",
          "job_city" => "Sydney", "job_state" => "NSW", "job_country" => "AU",
          "job_posted_at_datetime_utc" => "2026-10-01T00:00:00Z",
          "job_employment_type" => "FULLTIME",
          "job_is_remote" => true,
          "job_description" => "Build things",
          "job_apply_link" => "https://linkedin.com/jobs/1",
          "job_offer_expiration_datetime_utc" => "2026-12-01T00:00:00Z"
        }
      ]),
    )

    results = adapter.search(keyword: "ruby", location: "Sydney", remote: true, job_type: "full-time", count: 10)

    expect(results.size).to eq(1)
    job = results.first
    expect(job).to be_a(Domain::JobListing)
    expect(job.job_title).to eq("Ruby Developer")
    expect(job.company).to eq("Acme")
    expect(job.board_source).to eq("LinkedIn")
    expect(job.employment_type).to eq("full-time")
    expect(job.remote_type).to eq("remote")
    expect(job.location).to eq("Sydney, NSW, AU")
    expect(job.job_posted_date).to eq(Date.new(2026, 10, 1))
    expect(job.joe_status).to eq(0) # not yet expired
    expect(job.job_offer_expires_at).to eq(Time.zone.parse("2026-12-01T00:00:00Z"))
  end

  it "keeps JSearch's job_id so the listing can be re-checked later" do
    stub_request(:get, /jsearch\.p\.rapidapi\.com/).to_return(
      status: 200,
      body: jsearch_body([{ "job_id" => "YmluZzo2NjU5", "job_title" => "Dev", "job_publisher" => "Seek",
                            "job_description" => "d", "job_apply_link" => "https://x/1" }]),
    )

    job = adapter.search(keyword: "dev", location: nil, remote: false, job_type: nil, count: 10).first

    expect(job.jsearch_job_id).to eq("YmluZzo2NjU5")
    expect(job.job_offer_expires_at).to be_nil
  end

  describe "#expirations" do
    it "honors the JobExpirySourcePort contract" do
      expect(adapter).to be_a(JobExpirySourcePort)
    end

    it "asks job-details for comma-joined ids and maps each to its expiry" do
      details = stub_request(:get, %r{jsearch\.p\.rapidapi\.com/job-details})
        .with(query: hash_including("job_id" => "a,b"))
        .to_return(status: 200, body: { "status" => "OK", "data" => [
          { "job_id" => "a", "job_offer_expiration_datetime_utc" => "2026-11-07T00:00:00.000Z" },
          { "job_id" => "b", "job_offer_expiration_datetime_utc" => nil }
        ] }.to_json)

      result = adapter.expirations(job_ids: %w[a b])

      expect(details).to have_been_made.once
      expect(result).to eq("a" => Time.zone.parse("2026-11-07T00:00:00Z"), "b" => nil)
    end

    it "leaves out ids JSearch doesn't return" do
      stub_request(:get, %r{job-details}).to_return(status: 200, body: { "status" => "OK", "data" => [] }.to_json)

      expect(adapter.expirations(job_ids: ["gone"])).to eq({})
    end

    it "batches more than 20 ids into separate requests" do
      stub = stub_request(:get, %r{job-details}).to_return(status: 200, body: { "status" => "OK", "data" => [] }.to_json)

      adapter.expirations(job_ids: Array.new(25) { |i| "id#{i}" })

      expect(stub).to have_been_made.twice
    end

    it "makes no request when there are no ids" do
      expect(described_class.new(api_key: nil).expirations(job_ids: [])).to eq({})
    end
  end

  it "keeps any publisher as JSearch names it, and defaults a missing company" do
    stub_request(:get, /jsearch\.p\.rapidapi\.com/).to_return(
      status: 200,
      body: jsearch_body([
        { "job_title" => "Dev", "job_publisher" => "Glassdoor", "job_description" => "d", "job_apply_link" => "https://x/1" }
      ]),
    )

    job = adapter.search(keyword: "dev", location: nil, remote: false, job_type: nil, count: 10).first

    expect(job.board_source).to eq("Glassdoor")
    expect(job.company).to eq("Private Advertiser")
  end

  it "labels a job with no publisher Unknown" do
    stub_request(:get, /jsearch\.p\.rapidapi\.com/).to_return(
      status: 200,
      body: jsearch_body([{ "job_title" => "Dev", "job_publisher" => " ", "job_description" => "d", "job_apply_link" => "https://x/1" }]),
    )

    job = adapter.search(keyword: "dev", location: nil, remote: false, job_type: nil, count: 10).first

    expect(job.board_source).to eq("Unknown")
  end

  it "flags joe_status when the offer has expired" do
    stub_request(:get, /jsearch\.p\.rapidapi\.com/).to_return(
      status: 200,
      body: jsearch_body([
        { "job_title" => "Dev", "job_publisher" => "Seek", "job_description" => "d",
          "job_apply_link" => "https://x/1", "job_offer_expiration_datetime_utc" => "2020-01-01T00:00:00Z" }
      ]),
    )

    job = adapter.search(keyword: "dev", location: nil, remote: false, job_type: nil, count: 10).first

    expect(job.joe_status).to eq(1)
  end

  it "limits results to the requested count" do
    jobs = Array.new(25) { |i| { "job_title" => "Dev #{i}", "job_publisher" => "Seek", "job_description" => "d", "job_apply_link" => "https://x/#{i}" } }
    stub_request(:get, /jsearch\.p\.rapidapi\.com/).to_return(status: 200, body: jsearch_body(jobs))

    results = adapter.search(keyword: "dev", location: nil, remote: false, job_type: nil, count: 10)

    expect(results.size).to eq(10)
  end

  it "raises on a rate limit (429)" do
    stub_request(:get, /jsearch\.p\.rapidapi\.com/).to_return(status: 429, body: "")

    expect { adapter.search(keyword: "dev", location: nil, remote: false, job_type: nil, count: 10) }
      .to raise_error(Errors::ExternalServiceFailed, /rate limit/)
  end
end
