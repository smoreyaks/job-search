require "rails_helper"

RSpec.describe "Tracking", type: :request do
  def seed_tracking
    job = create_job_listing
    resume = create_resume
    cover = create_cover_letter
    comparison = create_comparison(resume: resume, job: job)
    create_tracking(job: job, resume: resume, comparison: comparison, cover: cover)
  end

  describe "GET /tracking" do
    it "returns all tracking entries" do
      seed_tracking

      get "/tracking"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
    end
  end

  describe "PATCH /tracking/rowSave" do
    it "updates one row's changed fields" do
      entry = seed_tracking

      patch "/tracking/rowSave", params: { id: entry.id, changed_fields: { applied: true, date_applied: "2026-10-20" } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["applied"]).to eq(true)
      expect(response.parsed_body["date_applied"]).to eq("2026-10-20")
    end

    it "marks the row's job dead (joe_status 2) through the row save path" do
      entry = seed_tracking

      patch "/tracking/rowSave", params: { id: entry.id, changed_fields: { joe_status: 2 } }

      expect(response).to have_http_status(:ok)
      expect(JobListing.find(entry.job_listing_id).joe_status).to eq(2)
    end

    it "saves nothing when the toggle is invalid" do
      entry = seed_tracking

      patch "/tracking/rowSave", params: { id: entry.id, changed_fields: { notes: "should not save", joe_status: 0 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Tracking.find(entry.id).notes).to be_nil
    end

    it "keeps a manually dead job red through a refresh while its new expiry date has passed" do
      entry = seed_tracking
      JobListing.find(entry.job_listing_id).update!(jsearch_job_id: "abc", job_offer_expires_at: 30.days.from_now)
      patch "/tracking/rowSave", params: { id: entry.id, changed_fields: { joe_status: 2 } }
      stub_const("ENV", ENV.to_h.merge("RAPIDAPI_KEY" => "test-key"))
      stub_request(:get, %r{jsearch\.p\.rapidapi\.com/job-details}).to_return(
        body: { data: [{ job_id: "abc", job_offer_expiration_datetime_utc: 2.days.ago.utc.iso8601 }] }.to_json
      )

      post "/jobs/refreshListings"

      expect(JobListing.find(entry.job_listing_id).joe_status).to eq(2)
      expect(response.parsed_body["checked"]).to eq(1)
    end

    it "returns 422 on an invalid date" do
      entry = seed_tracking

      patch "/tracking/rowSave", params: { id: entry.id, changed_fields: { interview_date: "nope" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /tracking/saveAll" do
    it "bulk-updates the changed rows" do
      a = seed_tracking
      b = seed_tracking

      patch "/tracking/saveAll", params: {
        changes: [
          { id: a.id, changed_fields: { applied: true } },
          { id: b.id, changed_fields: { follow_up_needed: true } }
        ]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "carries the mark-as-dead toggle for a row with no other changes" do
      a = seed_tracking

      patch "/tracking/saveAll", params: { changes: [{ id: a.id, changed_fields: { joe_status: 2 } }] }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |row| row["id"] }).to eq([a.id])
      expect(JobListing.find(a.job_listing_id).joe_status).to eq(2)
    end
  end
end
