require "rails_helper"

RSpec.describe JobsApiAdapter do
  subject(:adapter) { described_class.new(api_key: "test-key") }

  def search_body(jobs, next_token: nil)
    { "data" => jobs, "meta" => { "count" => jobs.size, "nextToken" => next_token },
      "errors" => [], "hasError" => false }.to_json
  end

  def get_body(job)
    { "data" => job, "errors" => [], "hasError" => false }.to_json
  end

  def summary(id, **overrides)
    { "id" => id, "title" => "Dev #{id}", "companyName" => "Acme", "location" => "Sydney, New South Wales, Australia",
      "datePosted" => "2026-10-14", "linkedinUrl" => "https://au.linkedin.com/jobs/view/#{id}" }.merge(overrides)
  end

  def search(**overrides)
    adapter.search(**{ keyword: "dev", location: nil, remote: false, job_type: nil, count: 10 }.merge(overrides))
  end

  it "honors the JobSourcePort, JobDetailsSourcePort and JobExpirySourcePort contracts" do
    expect(adapter).to be_a(JobSourcePort).and be_a(JobDetailsSourcePort).and be_a(JobExpirySourcePort)
  end

  it "raises a clear error when the API key is missing" do
    expect { described_class.new(api_key: nil).search(keyword: "dev", location: nil, remote: false, job_type: nil, count: 10) }
      .to raise_error(Errors::ExternalServiceFailed, /RAPIDAPI_KEY/)
  end

  it "maps LinkedIn summaries into Domain::JobListing entities with a blank description" do
    stub_request(:get, %r{jobs-api14\.p\.rapidapi\.com/v2/linkedin/search})
      .to_return(status: 200, body: search_body([summary("4470914440", "title" => "Software Engineer", "companyName" => "Cisco")]))

    job = search.first

    expect(job).to be_a(Domain::JobListing)
    expect(job).to have_attributes(
      job_title: "Software Engineer", company: "Cisco", board_source: "LinkedIn",
      location: "Sydney, New South Wales, Australia", job_posted_date: Date.new(2026, 10, 14),
      url: "https://au.linkedin.com/jobs/view/4470914440", jobs_api_job_id: "4470914440",
      job_description: "", employment_type: "full-time", remote_type: "on-site", jsearch_job_id: nil
    )
  end

  it "sends the keyword, location and filters the API expects" do
    stub = stub_request(:get, %r{v2/linkedin/search})
      .with(query: { "query" => "ruby", "location" => "Melbourne", "workplaceTypes" => "remote", "employmentTypes" => "contractor" })
      .to_return(status: 200, body: search_body([summary("1")]))

    job = search(keyword: " ruby ", location: "Melbourne", remote: true, job_type: "contract").first

    expect(stub).to have_been_made.once
    expect(job).to have_attributes(employment_type: "contract", remote_type: "remote")
  end

  it "searches Australia when no location is given" do
    stub = stub_request(:get, %r{v2/linkedin/search}).with(query: hash_including("location" => "Australia"))
      .to_return(status: 200, body: search_body([]))

    search(location: "  ")

    expect(stub).to have_been_made.once
  end

  it "maps casual to LinkedIn's temporary filter" do
    stub = stub_request(:get, %r{v2/linkedin/search}).with(query: hash_including("employmentTypes" => "temporary"))
      .to_return(status: 200, body: search_body([]))

    search(job_type: "casual")

    expect(stub).to have_been_made.once
  end

  describe "paging" do
    def stub_page(query, ids, next_token)
      stub_request(:get, %r{v2/linkedin/search}).with(query: query)
        .to_return(status: 200, body: search_body(ids.map { |id| summary(id) }, next_token: next_token))
    end

    let!(:page1) { stub_page(hash_including("query" => "dev"), Array.new(10) { |i| "a#{i}" }, "t2") }
    let!(:page2) { stub_page({ "token" => "t2" }, Array.new(10) { |i| "b#{i}" }, "t3") }
    let!(:page3) { stub_page({ "token" => "t3" }, Array.new(10) { |i| "c#{i}" }, nil) }

    it "follows nextToken, sending the token alone, until it has the count" do
      results = search(count: 30)

      expect(results.size).to eq(30)
      expect([page1, page2, page3]).to all(have_been_made.once)
    end

    it "makes one request for 10 results even when there are more pages" do
      expect(search(count: 10).size).to eq(10)
      expect(page1).to have_been_made.once
      expect(page2).not_to have_been_made
    end

    it "trims a page to a count below 10" do
      expect(search(count: 1).map(&:jobs_api_job_id)).to eq(["a0"])
    end
  end

  it "makes one request for 10 results and none extra when the API has no next page" do
    stub = stub_request(:get, %r{v2/linkedin/search})
      .to_return(status: 200, body: search_body(Array.new(4) { |i| summary(i.to_s) }))

    expect(search(count: 30).size).to eq(4)
    expect(stub).to have_been_made.once
  end

  it "raises on a rate limit (429)" do
    stub_request(:get, %r{v2/linkedin/search}).to_return(status: 429, body: "")

    expect { search }.to raise_error(Errors::ExternalServiceFailed, /rate limit/)
  end

  it "raises the API's own error message" do
    stub_request(:get, %r{v2/linkedin/search})
      .to_return(status: 200, body: { "data" => [], "errors" => ["query is required"], "hasError" => true }.to_json)

    expect { search }.to raise_error(Errors::ExternalServiceFailed, /query is required/)
  end

  describe "#details" do
    it "gets each job's description and employment type, one request per id" do
      a = stub_request(:get, %r{v2/linkedin/get}).with(query: { "id" => "a" })
        .to_return(status: 200, body: get_body("id" => "a", "description" => "Build things", "employmentType" => "Part-time"))
      b = stub_request(:get, %r{v2/linkedin/get}).with(query: { "id" => "b" })
        .to_return(status: 200, body: get_body("id" => "b", "description" => "Ship things", "employmentType" => "Temporary"))

      result = adapter.details(job_ids: %w[a b a])

      expect(a).to have_been_made.once
      expect(b).to have_been_made.once
      expect(result).to eq(
        "a" => { job_description: "Build things", employment_type: "part-time" },
        "b" => { job_description: "Ship things", employment_type: "casual" }
      )
    end

    it "leaves out an employment type it doesn't recognise" do
      stub_request(:get, %r{v2/linkedin/get})
        .to_return(status: 200, body: get_body("id" => "a", "description" => "d", "employmentType" => "Volunteer"))

      expect(adapter.details(job_ids: ["a"])).to eq("a" => { job_description: "d" })
    end

    it "leaves out a job the API reports an error for" do
      stub_request(:get, %r{v2/linkedin/get})
        .to_return(status: 200, body: { "data" => nil, "errors" => ["not found"], "hasError" => true }.to_json)

      expect(adapter.details(job_ids: ["gone"])).to eq({})
    end

    it "makes no request when there are no ids" do
      expect(described_class.new(api_key: nil).details(job_ids: [])).to eq({})
    end
  end

  describe "#expirations" do
    include ActiveSupport::Testing::TimeHelpers

    let(:now) { Time.zone.parse("2026-11-01 12:00") }

    it "treats a job no longer accepting applications as expired now, and gives no date otherwise" do
      stub_request(:get, %r{v2/linkedin/get}).with(query: { "id" => "closed" })
        .to_return(status: 200, body: get_body("id" => "closed", "acceptingApplications" => false))
      stub_request(:get, %r{v2/linkedin/get}).with(query: { "id" => "open" })
        .to_return(status: 200, body: get_body("id" => "open", "acceptingApplications" => true))

      result = travel_to(now) { adapter.expirations(job_ids: %w[closed open]) }

      expect(result).to eq("closed" => now, "open" => nil)
    end
  end
end
