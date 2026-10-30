require "rails_helper"

RSpec.describe "Compare and applications", type: :request do
  describe "POST /compare" do
    let(:job_params) do
      {
        board_source: "seek", company: "Acme", job_title: "Dev",
        job_posted_date: "2026-10-01", employment_type: "full-time",
        job_description: "d", url: "https://seek.com/1"
      }
    end

    it "returns 502 until Gemini is configured" do
      seed_config

      post "/compare", params: { resume_text: "my resume", job_listing: job_params }

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body["error"]).to match(/Gemini/)
    end

    it "returns 422 when resume text is blank" do
      seed_config

      post "/compare", params: { resume_text: "", job_listing: job_params }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /applications/save" do
    it "writes a comparison and tracking row and returns both" do
      job = create_job_listing
      resume = create_resume
      cover = create_cover_letter

      post "/applications/save", params: {
        resume_id: resume.id, job_listing_id: job.id, cover_letter_id: cover.id,
        match_score: 82, resume_suggestions: "add kubernetes"
      }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["comparison"]["match_score"].to_f).to eq(82.0)
      expect(response.parsed_body["tracking"]["comparison_id"]).to eq(response.parsed_body["comparison"]["id"])
      expect(Tracking.count).to eq(1)
      expect(Comparison.count).to eq(1)
    end
  end
end
