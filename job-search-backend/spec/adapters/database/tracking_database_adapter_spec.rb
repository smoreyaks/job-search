require "rails_helper"

RSpec.describe TrackingDatabaseAdapter do
  subject(:adapter) { described_class.new }

  let(:job) do
    JobListingDatabaseAdapter.new.save_all([
      Domain::JobListing.new(board_source: "seek", company: "Acme", job_title: "Dev",
                             job_posted_date: Date.new(2026, 10, 1), employment_type: "full-time",
                             job_description: "d", url: "https://seek.com/1")
    ]).first
  end
  let(:resume) { ResumeDatabaseAdapter.new.create(file_name: "cv.pdf", file_path: "/x/cv.pdf", version_note: "v1") }
  let(:cover)  { CoverLetterDatabaseAdapter.new.create(file_name: "cl.pdf", file_path: "/x/cl.pdf", version_note: "v1") }
  let(:comparison) do
    ComparisonDatabaseAdapter.new.create(resume_id: resume.id, job_listing_id: job.id,
                                         match_score: 80, resume_suggestions: "ok")
  end

  def create_entry
    adapter.create(job_listing_id: job.id, resume_id: resume.id,
                   comparison_id: comparison.id, cover_letter_id: cover.id)
  end

  it "honors the TrackingRepositoryPort contract" do
    expect(adapter).to be_a(TrackingRepositoryPort)
  end

  describe "#create" do
    it "persists and returns a Domain::TrackingEntry with boolean defaults" do
      entry = create_entry

      expect(Tracking.count).to eq(1)
      expect(entry).to be_a(Domain::TrackingEntry)
      expect(entry.id).to be_present
      expect(entry.applied).to eq(false)
      expect(entry.response_received).to eq(false)
      expect(entry.follow_up_needed).to eq(false)
    end
  end

  describe "#all" do
    it "returns entries newest first" do
      first = create_entry
      second = create_entry

      expect(adapter.all.map(&:id)).to eq([second.id, first.id])
    end
  end

  describe "#update" do
    it "applies the changed fields and returns the updated entity" do
      entry = create_entry

      updated = adapter.update(id: entry.id, changed_fields: { applied: true, notes: "sent" })

      expect(updated.applied).to eq(true)
      expect(updated.notes).to eq("sent")
      expect(Tracking.find(entry.id).applied).to eq(true)
    end
  end

  describe "#update_many" do
    it "updates many rows in one transaction" do
      a = create_entry
      b = create_entry

      adapter.update_many(changes: [
        { id: a.id, changed_fields: { applied: true } },
        { id: b.id, changed_fields: { follow_up_needed: true } }
      ])

      expect(Tracking.find(a.id).applied).to eq(true)
      expect(Tracking.find(b.id).follow_up_needed).to eq(true)
    end
  end
end
