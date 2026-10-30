require "rails_helper"

RSpec.describe ComparisonDatabaseAdapter do
  subject(:adapter) { described_class.new }

  let(:resume) do
    ResumeDatabaseAdapter.new.create(file_name: "cv.pdf", file_path: "/x/cv.pdf", version_note: "v1")
  end

  let(:job) do
    JobListingDatabaseAdapter.new.save_all([
      Domain::JobListing.new(board_source: "seek", company: "Acme", job_title: "Dev",
                             job_posted_date: Date.new(2026, 10, 1), employment_type: "full-time",
                             job_description: "d", url: "https://seek.com/1")
    ]).first
  end

  it "honors the ComparisonRepositoryPort contract" do
    expect(adapter).to be_a(ComparisonRepositoryPort)
  end

  describe "#create" do
    it "persists and returns a Domain::ComparisonResult with id and datetime" do
      result = adapter.create(resume_id: resume.id, job_listing_id: job.id,
                              match_score: 87.5, resume_suggestions: "add kubernetes")

      expect(Comparison.count).to eq(1)
      expect(result).to be_a(Domain::ComparisonResult)
      expect(result.id).to be_present
      expect(result.comparison_datetime).to be_present
      expect(result.match_score).to eq(87.5)
      expect(result.resume_suggestions).to eq("add kubernetes")
      expect(result.resume_id).to eq(resume.id)
      expect(result.job_listing_id).to eq(job.id)
    end
  end
end
