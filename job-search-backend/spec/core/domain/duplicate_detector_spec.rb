require "rails_helper"

RSpec.describe Domain::DuplicateDetector do
  subject(:detector) { described_class.new }

  def listing(**overrides)
    defaults = {
      board_source: "seek", company: "Acme Corp", job_title: "Ruby Developer",
      location: "Sydney", salary_range: "$120k", job_posted_date: Date.new(2026, 10, 10),
      employment_type: "full-time", job_description: "d", url: "https://x/1"
    }
    Domain::JobListing.new(**defaults.merge(overrides))
  end

  it "flags a near-identical listing within the date window" do
    candidate = listing
    existing = [listing(board_source: "indeed", company: "Acme Corp.", job_posted_date: Date.new(2026, 10, 12), url: "https://y/1")]

    expect(detector.find_duplicate(candidate, existing)).to eq(existing.first)
  end

  it "ignores board_source when matching (same job across boards)" do
    candidate = listing(board_source: "seek")
    existing = [listing(board_source: "linkedin", url: "https://y/2")]

    expect(detector.find_duplicate(candidate, existing)).not_to be_nil
  end

  it "handles an ISO string date (as the controller builds from JSON) without crashing" do
    candidate = listing(job_posted_date: "2026-10-10") # string, straight from JSON
    existing = [listing(job_posted_date: Date.new(2026, 10, 12), url: "https://y/str")]

    expect(detector.find_duplicate(candidate, existing)).to eq(existing.first)
  end

  it "does not flag a match outside the +/- 3 day window" do
    candidate = listing(job_posted_date: Date.new(2026, 10, 10))
    existing = [listing(job_posted_date: Date.new(2026, 10, 20), url: "https://y/3")]

    expect(detector.find_duplicate(candidate, existing)).to be_nil
  end

  it "does not flag listings with clearly different titles/companies" do
    candidate = listing(company: "Acme Corp", job_title: "Ruby Developer")
    existing = [listing(company: "Globex", job_title: "Data Scientist", url: "https://y/4")]

    expect(detector.find_duplicate(candidate, existing)).to be_nil
  end

  context "when the company is a Private Advertiser" do
    it "falls back to title + location + salary (no date window)" do
      candidate = listing(company: "Private Advertiser", job_posted_date: Date.new(2026, 10, 10))
      existing = [listing(company: "Private Advertiser", job_posted_date: Date.new(2026, 11, 30), url: "https://y/5")]

      expect(detector.find_duplicate(candidate, existing)).to eq(existing.first)
    end

    it "does not flag when location/salary differ" do
      candidate = listing(company: "Private Advertiser", location: "Sydney", salary_range: "$120k")
      existing = [listing(company: "Private Advertiser", location: "Perth", salary_range: "$80k", url: "https://y/6")]

      expect(detector.find_duplicate(candidate, existing)).to be_nil
    end
  end
end
