require "rails_helper"

RSpec.describe UseCases::RefreshListings do
  let(:now) { Time.zone.parse("2026-10-20 12:00") }

  def listing(id:, job_id:, expires_at: nil, joe_status: 0)
    Domain::JobListing.new(id: id, board_source: "seek", company: "Acme", job_title: "Dev",
                           job_posted_date: Date.new(2026, 10, 1), employment_type: "full-time",
                           job_description: "d", url: "https://jobs/#{id}", joe_status: joe_status,
                           jsearch_job_id: job_id, job_offer_expires_at: expires_at)
  end

  def build(repo, source)
    described_class.new(repository: repo, expiry_source: source, clock: -> { now })
  end

  it "stores the fresh expiry from the source and re-runs the Joe check" do
    repo = Fakes::JobListingRepository.new([
      listing(id: 1, job_id: "a", expires_at: now + 5.days),
      listing(id: 2, job_id: "b", expires_at: now + 5.days)
    ])
    source = Fakes::JobExpirySource.new("a" => now + 10.days, "b" => now - 1.hour)

    result = build(repo, source).call
    rows = result[:listings].to_h { |l| [l.id, l] }

    expect(rows[1]).to have_attributes(joe_status: 0, status: "active", job_offer_expires_at: now + 10.days)
    expect(rows[2]).to have_attributes(joe_status: 1, status: "closed", job_offer_expires_at: now - 1.hour)
    expect(result[:checked]).to eq(2)
  end

  it "keeps the old expiry for a job the source no longer returns" do
    repo = Fakes::JobListingRepository.new([listing(id: 1, job_id: "gone", expires_at: now + 2.days)])

    result = build(repo, Fakes::JobExpirySource.new).call

    expect(result[:listings].first).to have_attributes(joe_status: 0, job_offer_expires_at: now + 2.days)
  end

  it "asks about every listing with a job id, manually dead ones included" do
    repo = Fakes::JobListingRepository.new([
      listing(id: 1, job_id: "a"),
      listing(id: 2, job_id: nil),
      listing(id: 3, job_id: "c", joe_status: 2)
    ])
    source = Fakes::JobExpirySource.new("a" => now + 1.day, "c" => now - 1.day)

    result = build(repo, source).call

    expect(source.requested_ids).to contain_exactly("a", "c")
    expect(result[:checked]).to eq(2)
  end

  describe "the 23 Oct Joe status rules" do
    def refresh_one(joe_status:, old_expiry:, fresh_expiry:)
      repo = Fakes::JobListingRepository.new([listing(id: 1, job_id: "a", joe_status: joe_status, expires_at: old_expiry)])
      fresh = fresh_expiry ? { "a" => fresh_expiry } : {}
      build(repo, Fakes::JobExpirySource.new(fresh)).call[:listings].first
    end

    it "returns an amber listing to green when the new date is ahead" do
      expect(refresh_one(joe_status: 1, old_expiry: now - 1.day, fresh_expiry: now + 7.days))
        .to have_attributes(joe_status: 0, status: "active")
    end

    it "turns a green listing amber when the new date has passed" do
      expect(refresh_one(joe_status: 0, old_expiry: now + 1.day, fresh_expiry: now - 1.hour))
        .to have_attributes(joe_status: 1, status: "closed")
    end

    it "keeps a manually dead listing red while the new date has passed" do
      expect(refresh_one(joe_status: 2, old_expiry: now - 3.days, fresh_expiry: now - 1.day))
        .to have_attributes(joe_status: 2, status: "closed", job_offer_expires_at: now - 1.day)
    end

    it "returns a manually dead listing to green when the new date is ahead" do
      expect(refresh_one(joe_status: 2, old_expiry: now - 3.days, fresh_expiry: now + 14.days))
        .to have_attributes(joe_status: 0, status: "active")
    end

    it "leaves a listing unchanged when JSearch returns no date for it" do
      expect(refresh_one(joe_status: 2, old_expiry: now + 5.days, fresh_expiry: nil))
        .to have_attributes(joe_status: 2, job_offer_expires_at: now + 5.days)
    end
  end

  describe "listings saved from the Jobs API" do
    def jobs_api_listing(id:, job_id:, joe_status: 0)
      listing(id: id, job_id: nil, joe_status: joe_status).with(jobs_api_job_id: job_id)
    end

    it "asks each API only about its own listings" do
      repo = Fakes::JobListingRepository.new([
        listing(id: 1, job_id: "js"),
        jobs_api_listing(id: 2, job_id: "li")
      ])
      jsearch = Fakes::JobExpirySource.new("js" => now + 1.day)
      jobs_api = Fakes::JobExpirySource.new("li" => now)

      result = described_class.new(repository: repo, expiry_source: jsearch, jobs_api_expiry_source: jobs_api,
                                   clock: -> { now + 1.second }).call
      rows = result[:listings].to_h { |l| [l.id, l] }

      expect(jsearch.requested_ids).to eq(["js"])
      expect(jobs_api.requested_ids).to eq(["li"])
      expect(rows[1]).to have_attributes(joe_status: 0)
      expect(rows[2]).to have_attributes(joe_status: 1, status: "closed")
      expect(result[:checked]).to eq(2)
    end

    it "skips them when no Jobs API source is given" do
      repo = Fakes::JobListingRepository.new([jobs_api_listing(id: 1, job_id: "li")])

      expect(build(repo, Fakes::JobExpirySource.new).call[:checked]).to eq(0)
    end
  end
end
