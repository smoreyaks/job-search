require "rails_helper"

RSpec.describe JobListingDatabaseAdapter do
  subject(:adapter) { described_class.new }

  def build_listing(**overrides)
    defaults = {
      board_source: "seek",
      company: "Acme",
      job_title: "Ruby Dev",
      job_posted_date: Date.new(2026, 10, 1),
      employment_type: "full-time",
      job_description: "Build things",
      url: "https://seek.com/1"
    }
    Domain::JobListing.new(**defaults.merge(overrides))
  end

  it "honors the JobListingRepositoryPort contract" do
    expect(adapter).to be_a(JobListingRepositoryPort)
  end

  describe "#save_all" do
    it "persists the listings and returns Domain::JobListing entities with ids" do
      saved = adapter.save_all([build_listing, build_listing(url: "https://seek.com/2")])

      expect(JobListing.count).to eq(2)
      expect(saved).to all(be_a(Domain::JobListing))
      expect(saved.map(&:id)).to all(be_present)
    end

    it "applies database defaults on the returned entity" do
      saved = adapter.save_all([build_listing]).first

      expect(saved.status).to eq("active")
      expect(saved.joe_status).to eq(0)
      expect(saved.salary_range).to eq("N/A")
      expect(saved.date_saved).to be_present
    end

    it "round-trips enum-style values as their canonical strings" do
      saved = adapter.save_all([build_listing(employment_type: "part-time", remote_type: "on-site")]).first

      expect(saved.employment_type).to eq("part-time")
      expect(saved.remote_type).to eq("on-site")
    end

    it "accepts any publisher name as the board source" do
      saved = adapter.save_all([build_listing(board_source: "Glassdoor")]).first

      expect(saved.board_source).to eq("Glassdoor")
    end

    it "is atomic: a single invalid listing rolls back the whole batch" do
      batch = [build_listing, build_listing(employment_type: "freelance", url: "https://x/2")]

      expect { adapter.save_all(batch) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(JobListing.count).to eq(0)
    end
  end

  describe "#all" do
    it "returns non-archived listings as entities, newest first" do
      older = adapter.save_all([build_listing(url: "https://seek.com/old", date_saved: 2.days.ago)]).first
      newer = adapter.save_all([build_listing(url: "https://seek.com/new", date_saved: 1.day.ago)]).first

      result = adapter.all

      expect(result).to all(be_a(Domain::JobListing))
      expect(result.map(&:id)).to eq([newer.id, older.id])
    end

    it "breaks ties on id when date_saved is identical (one bulk save)" do
      saved = adapter.save_all([
        build_listing(url: "https://seek.com/a"),
        build_listing(url: "https://seek.com/b")
      ])

      expect(adapter.all.map(&:id)).to eq(saved.map(&:id).sort.reverse)
    end

    it "excludes archived listings" do
      kept = adapter.save_all([build_listing(url: "https://seek.com/keep")]).first
      gone = adapter.save_all([build_listing(url: "https://seek.com/gone")]).first
      JobListing.find(gone.id).update!(archived_at: Time.current)

      expect(adapter.all.map(&:id)).to eq([kept.id])
    end
  end

  describe "#find_candidates" do
    it "returns non-archived listings as entities for duplicate matching" do
      adapter.save_all([build_listing, build_listing(url: "https://seek.com/2")])

      candidates = adapter.find_candidates(build_listing)

      expect(candidates.size).to eq(2)
      expect(candidates).to all(be_a(Domain::JobListing))
    end
  end

  describe "#refresh_all" do
    it "updates existing rows by id without inserting" do
      saved = adapter.save_all([build_listing]).first

      adapter.refresh_all([saved.with(company: "Acme Renamed", joe_status: 1)])

      expect(JobListing.count).to eq(1)
      row = JobListing.find(saved.id)
      expect(row.company).to eq("Acme Renamed")
      expect(row.joe_status).to eq(1)
    end

    it "writes a manually dead row as given, since the use case applies the latch" do
      saved = adapter.save_all([build_listing]).first
      JobListing.find(saved.id).update!(joe_status: 2)

      adapter.refresh_all([saved.with(joe_status: 0, status: "active")])

      expect(JobListing.find(saved.id).joe_status).to eq(0)
    end

    it "skips entities whose id no longer exists" do
      adapter.save_all([build_listing])
      phantom = build_listing(url: "https://seek.com/phantom").with(id: 999_999)

      expect { adapter.refresh_all([phantom]) }.not_to change(JobListing, :count)
    end
  end
end
