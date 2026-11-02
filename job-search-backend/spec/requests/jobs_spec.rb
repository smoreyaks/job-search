require "rails_helper"

RSpec.describe "Jobs", type: :request do
  describe "GET /jobs/savedList" do
    it "returns the saved listings as JSON" do
      create_job_listing(url: "https://seek.com/a")

      get "/jobs/savedList"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["url"]).to eq("https://seek.com/a")
    end
  end

  describe "POST /jobs/saveAll" do
    let(:listing_params) do
      {
        board_source: "seek", company: "Acme", job_title: "Ruby Dev",
        job_posted_date: "2026-10-01", employment_type: "full-time",
        job_description: "Build things", url: "https://seek.com/new"
      }
    end

    it "saves the posted listings and returns them with warnings" do
      post "/jobs/saveAll", params: { listings: [listing_params] }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["saved"].size).to eq(1)
      expect(response.parsed_body["saved"].first["id"]).to be_present
      expect(response.parsed_body["warnings"]).to eq([])
    end

    it "returns 422 when a required field is missing" do
      post "/jobs/saveAll", params: { listings: [listing_params.except(:company)] }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "fetches a Jobs API listing's description before saving it" do
      stub_const("ENV", ENV.to_h.merge("RAPIDAPI_KEY" => "test-key"))
      details = stub_request(:get, %r{jobs-api14\.p\.rapidapi\.com/v2/linkedin/get}).with(query: { "id" => "7" })
        .to_return(status: 200, body: { data: { id: "7", description: "The full job ad", employmentType: "Full-time" },
                                        hasError: false }.to_json)

      post "/jobs/saveAll", params: { listings: [listing_params.merge(job_description: "", jobs_api_job_id: "7")] }

      expect(details).to have_been_made.once
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["saved"].first).to include("job_description" => "The full job ad", "jobs_api_job_id" => "7")
    end

    it "flags a duplicate of an already-saved listing while still saving" do
      create_job_listing(company: "Acme", job_title: "Ruby Dev", job_posted_date: Date.new(2026, 10, 2), url: "https://old/1")

      post "/jobs/saveAll", params: { listings: [listing_params] } # same company/title, 2026-10-01

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["saved"].size).to eq(1)
      expect(response.parsed_body["warnings"].size).to eq(1)
      expect(response.parsed_body["warnings"].first["likely_match"]["url"]).to eq("https://old/1")
    end
  end

  describe "GET /jobs/search" do
    it "returns 502 until JSearch is configured" do
      get "/jobs/search", params: { keyword: "ruby" }

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body["error"]).to match(/JSearch/)
    end

    it "returns 422 when the keyword is missing" do
      get "/jobs/search", params: { keyword: "" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for an unknown source" do
      get "/jobs/search", params: { keyword: "ruby", source: "monster" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for an unsupported country" do
      get "/jobs/search", params: { keyword: "ruby", country: "nz" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "searches the Jobs API when it's the chosen source" do
      stub_const("ENV", ENV.to_h.merge("RAPIDAPI_KEY" => "test-key"))
      search = stub_request(:get, %r{jobs-api14\.p\.rapidapi\.com/v2/linkedin/search})
        .with(query: hash_including("query" => "ruby", "location" => "Sydney, Australia"))
        .to_return(status: 200, body: { data: [{ id: "7", title: "Ruby Dev", companyName: "Acme",
                                                 datePosted: "2026-10-30", linkedinUrl: "https://au.linkedin.com/jobs/view/7" }],
                                        meta: { nextToken: nil }, hasError: false }.to_json)

      get "/jobs/search", params: { keyword: "ruby", location: "Sydney", source: "jobs_api" }

      expect(search).to have_been_made.once
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.first).to include("job_title" => "Ruby Dev", "board_source" => "LinkedIn",
                                                    "jobs_api_job_id" => "7", "job_description" => "")
    end
  end

  describe "POST /jobs/refreshListings" do
    def stub_details(job_id, expires)
      stub_request(:get, %r{jsearch\.p\.rapidapi\.com/job-details}).with(query: hash_including("job_id" => job_id))
        .to_return(status: 200, body: { status: "OK",
                                        data: [{ job_id: job_id, job_offer_expiration_datetime_utc: expires }] }.to_json)
    end

    before { stub_const("ENV", ENV.to_h.merge("RAPIDAPI_KEY" => "test-key")) }

    it "asks JSearch's job-details for each saved job id and updates expiry" do
      create_job_listing(jsearch_job_id: "abc", job_offer_expires_at: 5.days.from_now)
      details = stub_details("abc", "2020-01-01T00:00:00Z")

      post "/jobs/refreshListings"

      expect(details).to have_been_made.once
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["checked"]).to eq(1)
      expect(response.parsed_body["listings"].first).to include("joe_status" => 1, "status" => "closed")
    end

    it "brings a job back to live when the employer extended its expiry" do
      create_job_listing(jsearch_job_id: "abc", job_offer_expires_at: 2.days.ago, joe_status: 1, status: "closed")
      stub_details("abc", 30.days.from_now.utc.iso8601)

      post "/jobs/refreshListings"

      expect(response.parsed_body["listings"].first).to include("joe_status" => 0, "status" => "active")
    end

    it "returns 502 when the JSearch key is missing" do
      create_job_listing(jsearch_job_id: "abc")
      stub_const("ENV", ENV.to_h.except("RAPIDAPI_KEY"))

      post "/jobs/refreshListings"

      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
