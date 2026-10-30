require "rails_helper"

RSpec.describe UseCases::SaveJobListings do
  subject(:use_case) { described_class.new(repository: repository) }

  let(:repository) { Fakes::JobListingRepository.new(existing) }
  let(:existing) { [] }

  def listing(**overrides)
    defaults = {
      board_source: "seek", company: "Acme Corp", job_title: "Ruby Developer",
      location: "Sydney", salary_range: "$120k", job_posted_date: Date.new(2026, 10, 10),
      employment_type: "full-time", job_description: "d", url: "https://x/1"
    }
    Domain::JobListing.new(**defaults.merge(overrides))
  end

  it "saves the listings and returns them with assigned ids" do
    result = use_case.call(listings: [listing, listing(url: "https://x/2")])

    expect(result[:saved].size).to eq(2)
    expect(result[:saved].map(&:id)).to all(be_present)
    expect(repository.rows.size).to eq(2)
  end

  it "rejects an empty batch" do
    expect { use_case.call(listings: []) }.to raise_error(Errors::ValidationFailed)
  end

  context "when an incoming listing duplicates an existing one" do
    let(:existing) do
      [listing(id: 99, company: "Acme Corp.", job_posted_date: Date.new(2026, 10, 11), url: "https://old/1")]
    end

    it "returns a soft warning but still saves" do
      result = use_case.call(listings: [listing])

      expect(result[:warnings].size).to eq(1)
      expect(result[:warnings].first[:likely_match].id).to eq(99)
      expect(result[:saved].size).to eq(1)
    end
  end
end
