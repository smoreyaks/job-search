# Composition root. The one place that knows which concrete adapter fulfills
# each port and builds every use case with its dependencies. Controllers ask the
# container for a use case and never instantiate adapters themselves.
#
# Objects are stateless, so each accessor builds a fresh instance (cheap and
# reload-safe in development). Constants are referenced inside method bodies so
# they resolve via autoload at call time, not at boot.
module Container
  class << self
    # --- database adapters ---
    def job_listings_repository = JobListingDatabaseAdapter.new
    def resumes_repository      = ResumeDatabaseAdapter.new
    def cover_letters_repository = CoverLetterDatabaseAdapter.new
    def comparisons_repository  = ComparisonDatabaseAdapter.new
    def tracking_repository     = TrackingDatabaseAdapter.new
    def config_repository       = ConfigDatabaseAdapter.new
    def unit_of_work            = ActiveRecordTransactionAdapter.new
    def file_storage            = LocalDiskStorageAdapter.new

    # --- external adapters ---
    def job_source     = JSearchAdapter.new
    def job_expiry_source = JSearchAdapter.new
    def jobs_api       = JobsApiAdapter.new
    def match_analyzer = GeminiMatchAnalyzerAdapter.new
    def resume_rewriter = GeminiResumeRewriterAdapter.new

    # The Search page's API selector: source name => JobSourcePort.
    def job_sources = { "jsearch" => job_source, "jobs_api" => jobs_api }

    # --- use cases ---
    def search_jobs
      UseCases::SearchJobs.new(job_sources: job_sources)
    end

    def save_job_listings
      UseCases::SaveJobListings.new(repository: job_listings_repository, details_source: jobs_api)
    end

    def list_job_listings
      UseCases::ListJobListings.new(repository: job_listings_repository)
    end

    def refresh_listings
      UseCases::RefreshListings.new(
        repository: job_listings_repository, expiry_source: job_expiry_source, jobs_api_expiry_source: jobs_api
      )
    end

    def list_resumes
      UseCases::ListResumes.new(repository: resumes_repository)
    end

    def list_cover_letters
      UseCases::ListCoverLetters.new(repository: cover_letters_repository)
    end

    def upload_resume
      UseCases::UploadResume.new(resumes: resumes_repository, file_storage: file_storage, config: config_repository)
    end

    def upload_cover_letter
      UseCases::UploadCoverLetter.new(cover_letters: cover_letters_repository, file_storage: file_storage, config: config_repository)
    end

    def read_resume_file
      UseCases::ReadDocumentFile.new(documents: resumes_repository, file_storage: file_storage, config: config_repository)
    end

    def read_cover_letter_file
      UseCases::ReadDocumentFile.new(documents: cover_letters_repository, file_storage: file_storage, config: config_repository)
    end

    def compare_resume_to_job
      UseCases::CompareResumeToJob.new(analyzer: match_analyzer, config: config_repository)
    end

    def modify_resume
      UseCases::ModifyResume.new(rewriter: resume_rewriter)
    end

    def save_application
      UseCases::SaveApplication.new(
        comparisons: comparisons_repository, tracking: tracking_repository, unit_of_work: unit_of_work
      )
    end

    def list_tracking_entries
      UseCases::ListTrackingEntries.new(repository: tracking_repository)
    end

    def update_tracking_entry
      UseCases::UpdateTrackingEntry.new(
        repository: tracking_repository, job_listings: job_listings_repository, unit_of_work: unit_of_work
      )
    end

    def bulk_update_tracking_entries
      UseCases::BulkUpdateTrackingEntries.new(
        repository: tracking_repository, job_listings: job_listings_repository, unit_of_work: unit_of_work
      )
    end

    def get_config
      UseCases::GetConfig.new(repository: config_repository)
    end

    def update_config
      UseCases::UpdateConfig.new(repository: config_repository)
    end
  end
end
