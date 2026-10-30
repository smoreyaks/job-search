require "rails_helper"

RSpec.describe "Tracking use cases" do
  let(:repository) { Fakes::TrackingRepository.new }
  let(:job_listings) { Fakes::JobListingRepository.new([job(id: 1, joe_status: 1)]) }
  let(:deps) { { repository: repository, job_listings: job_listings, unit_of_work: Fakes::UnitOfWork.new } }

  def job(id:, joe_status:)
    Domain::JobListing.new(id: id, board_source: "seek", company: "Acme", job_title: "Dev",
                           job_posted_date: Date.new(2026, 10, 1), employment_type: "full-time",
                           job_description: "d", url: "https://jobs/#{id}", joe_status: joe_status)
  end

  def seed_entry
    repository.create(job_listing_id: 1, resume_id: 2, comparison_id: 3, cover_letter_id: 4)
  end

  describe UseCases::ListTrackingEntries do
    it "returns all entries, newest first" do
      a = seed_entry
      b = seed_entry

      expect(described_class.new(repository: repository).call.map(&:id)).to eq([b.id, a.id])
    end
  end

  describe UseCases::UpdateTrackingEntry do
    subject(:use_case) { described_class.new(**deps) }

    it "applies sanitized editable fields" do
      entry = seed_entry

      updated = use_case.call(id: entry.id, changed_fields: { applied: "true", date_applied: "2026-10-20" })

      expect(updated.applied).to eq(true)
      expect(updated.date_applied).to eq(Date.new(2026, 10, 20))
    end

    it "raises when no editable fields are present" do
      entry = seed_entry

      expect { use_case.call(id: entry.id, changed_fields: { job_listing_id: 99 }) }
        .to raise_error(Errors::ValidationFailed, /no editable fields/)
    end

    it "marks the row's job dead when the toggle is the only change" do
      entry = seed_entry

      result = use_case.call(id: entry.id, changed_fields: { joe_status: 2 })

      expect(result.id).to eq(entry.id)
      expect(job_listings.all.first.joe_status).to eq(2)
    end

    it "saves tracking fields and the toggle together" do
      entry = seed_entry

      result = use_case.call(id: entry.id, changed_fields: { notes: "Closed per recruiter", joe_status: "2" })

      expect(result.notes).to eq("Closed per recruiter")
      expect(job_listings.all.first.joe_status).to eq(2)
    end

    it "un-marks back to expired (1), never to good (0)" do
      entry = seed_entry
      job_listings.set_joe_status(id: 1, joe_status: 2)

      use_case.call(id: entry.id, changed_fields: { joe_status: 1 })
      expect(job_listings.all.first.joe_status).to eq(1)

      expect { use_case.call(id: entry.id, changed_fields: { joe_status: 0 }) }
        .to raise_error(Errors::ValidationFailed, /1 or 2/)
    end

    it "rejects a toggle value that isn't a number" do
      entry = seed_entry

      expect { use_case.call(id: entry.id, changed_fields: { joe_status: "dead" }) }
        .to raise_error(Errors::ValidationFailed, /joe_status/)
    end

    it "raises when id is missing" do
      expect { use_case.call(id: nil, changed_fields: { applied: true }) }
        .to raise_error(Errors::ValidationFailed, /id/)
    end
  end

  describe UseCases::BulkUpdateTrackingEntries do
    subject(:use_case) { described_class.new(**deps) }

    it "updates every changed row and skips rows with no editable changes" do
      a = seed_entry
      b = seed_entry

      result = use_case.call(changes: [
        { id: a.id, changed_fields: { applied: true } },
        { id: b.id, changed_fields: { job_listing_id: 99 } } # no editable field -> skipped
      ])

      expect(result.size).to eq(1)
      expect(result.first.id).to eq(a.id)
      expect(result.first.applied).to eq(true)
    end

    it "returns toggle-only rows too, and writes the toggle to their jobs" do
      a = seed_entry
      b = seed_entry

      result = use_case.call(changes: [
        { id: a.id, changed_fields: { applied: true } },
        { id: b.id, changed_fields: { joe_status: 2 } }
      ])

      expect(result.map(&:id)).to eq([a.id, b.id])
      expect(job_listings.all.first.joe_status).to eq(2)
    end

    it "returns an empty array when nothing changed" do
      expect(use_case.call(changes: [])).to eq([])
    end
  end
end
