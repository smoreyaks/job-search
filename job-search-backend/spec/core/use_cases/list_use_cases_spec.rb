require "rails_helper"

RSpec.describe "Edit-page list use cases" do
  describe UseCases::ListJobListings do
    it "returns the repository's listings" do
      repo = Fakes::JobListingRepository.new
      listing = Domain::JobListing.new(board_source: "seek", company: "Acme", job_title: "Dev",
                                       job_posted_date: Date.new(2026, 10, 1), employment_type: "full-time",
                                       job_description: "d", url: "https://x/1")
      repo.save_all([listing])

      expect(described_class.new(repository: repo).call.size).to eq(1)
    end
  end

  describe UseCases::ListResumes do
    it "returns the repository's resumes" do
      repo = Fakes::ResumeRepository.new
      repo.create(file_name: "cv.pdf", file_path: "/x/cv.pdf", version_note: "v1")

      expect(described_class.new(repository: repo).call.size).to eq(1)
    end
  end

  describe UseCases::ListCoverLetters do
    it "returns the repository's cover letters" do
      repo = Fakes::CoverLetterRepository.new
      repo.create(file_name: "cl.pdf", file_path: "/x/cl.pdf", version_note: "v1")

      expect(described_class.new(repository: repo).call.size).to eq(1)
    end
  end
end
