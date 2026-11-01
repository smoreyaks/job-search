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

  context "with listings from the Jobs API" do
    subject(:use_case) { described_class.new(repository: repository, details_source: details_source) }

    let(:details_source) do
      Fakes::JobDetailsSource.new("li-1" => { job_description: "Full description", employment_type: "contract" })
    end

    it "fills in the description (and employment type) before saving" do
      result = use_case.call(listings: [listing(jobs_api_job_id: "li-1", job_description: "")])

      expect(details_source.requested_ids).to eq(["li-1"])
      expect(result[:saved].first).to have_attributes(job_description: "Full description", employment_type: "contract")
    end

    it "only asks about Jobs API listings that have no description" do
      use_case.call(listings: [
        listing(jobs_api_job_id: "li-1", job_description: "", url: "https://x/1"),
        listing(jobs_api_job_id: "li-2", job_description: "already here", url: "https://x/2"),
        listing(jsearch_job_id: "js-1", url: "https://x/3")
      ])

      expect(details_source.requested_ids).to eq(["li-1"])
    end

    it "makes no request when nothing needs details" do
      use_case.call(listings: [listing])

      expect(details_source.requested_ids).to be_nil
    end

    it "saves nothing when a description can't be fetched" do
      expect { use_case.call(listings: [listing(jobs_api_job_id: "gone", job_description: "")]) }
        .to raise_error(Errors::ExternalServiceFailed, /description/)
      expect(repository.rows).to be_empty
    end
  end
end
