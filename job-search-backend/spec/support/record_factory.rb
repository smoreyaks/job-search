# Helpers that seed real DB rows (via the database adapters) for request specs.
module RecordFactory
  def create_job_listing(**overrides)
    JobListingDatabaseAdapter.new.save_all([
      Domain::JobListing.new(**{
        board_source: "seek", company: "Acme", job_title: "Ruby Dev",
        job_posted_date: Date.new(2026, 10, 1), employment_type: "full-time",
        job_description: "d", url: "https://seek.com/1"
      }.merge(overrides))
    ]).first
  end

  def create_resume(**overrides)
    ResumeDatabaseAdapter.new.create(**{
      file_name: "cv.pdf", file_path: "/x/cv.pdf", version_note: "v1"
    }.merge(overrides))
  end

  def create_cover_letter(**overrides)
    CoverLetterDatabaseAdapter.new.create(**{
      file_name: "cl.pdf", file_path: "/x/cl.pdf", version_note: "v1"
    }.merge(overrides))
  end

  def create_comparison(resume:, job:)
    ComparisonDatabaseAdapter.new.create(
      resume_id: resume.id, job_listing_id: job.id, match_score: 80, resume_suggestions: "ok"
    )
  end

  def create_tracking(job:, resume:, comparison:, cover:)
    TrackingDatabaseAdapter.new.create(
      job_listing_id: job.id, resume_id: resume.id,
      comparison_id: comparison.id, cover_letter_id: cover.id
    )
  end

  def seed_config(**overrides)
    Config.create!(**{ local_app_data: "/localAppData/resume", delimiter: "@@@startdelim@@@" }.merge(overrides))
  end
end

RSpec.configure do |config|
  config.include RecordFactory, type: :request
end
