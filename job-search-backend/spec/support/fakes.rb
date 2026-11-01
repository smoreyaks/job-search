# In-memory fake adapters for use-case specs. Each fulfills a port contract so
# core logic can be tested without a database or external service.
module Fakes
  # Fulfills JobSourcePort. Returns canned results and records the last call.
  class JobSource
    include JobSourcePort

    attr_reader :last_args

    def initialize(results: [])
      @results = results
      @last_args = nil
    end

    def search(**args)
      @last_args = args
      @results
    end
  end

  # Fulfills JobDetailsSourcePort. Returns the canned details for each known id
  # (unknown ids are left out, like a job the source removed) and records calls.
  class JobDetailsSource
    include JobDetailsSourcePort

    attr_reader :requested_ids

    def initialize(details = {})
      @details = details
      @requested_ids = nil
    end

    def details(job_ids:)
      @requested_ids = job_ids
      @details.slice(*job_ids)
    end
  end

  # Fulfills JobListingRepositoryPort with an in-memory store.
  class JobListingRepository
    include JobListingRepositoryPort

    attr_reader :rows

    def initialize(existing = [])
      @rows = existing.dup
      @next_id = (@rows.map(&:id).compact.max || 0) + 1
    end

    def all
      @rows.reject(&:archived?)
    end

    def save_all(listings)
      listings.map do |listing|
        saved = listing.with(id: @next_id, date_saved: Time.current)
        @next_id += 1
        @rows << saved
        saved
      end
    end

    def find_candidates(_listing)
      all
    end

    def refresh_all(listings)
      listings.filter_map do |entity|
        index = @rows.index { |row| row.id == entity.id }
        next if index.nil?

        @rows[index] = entity
        @rows[index]
      end
    end

    def set_joe_status(id:, joe_status:)
      index = @rows.index { |row| row.id == id }
      raise Errors::NotFound, "job listing #{id} not found" if index.nil?

      @rows[index] = @rows[index].with(joe_status: joe_status)
    end
  end

  # Fulfills JobExpirySourcePort. Returns the canned expiry for each known id
  # (unknown ids are left out, like a job the source dropped) and records calls.
  class JobExpirySource
    include JobExpirySourcePort

    attr_reader :requested_ids

    def initialize(expirations = {})
      @expirations = expirations
      @requested_ids = nil
    end

    def expirations(job_ids:)
      @requested_ids = job_ids
      @expirations.slice(*job_ids)
    end
  end

  # Fulfills ResumeRepositoryPort with an in-memory store.
  class ResumeRepository
    include ResumeRepositoryPort

    attr_reader :rows

    def initialize
      @rows = []
      @next_id = 1
    end

    def find(id)
      @rows.find { |row| row.id == id.to_i } || raise(Errors::NotFound, "document #{id} not found")
    end

    def all
      @rows.reject(&:archived?)
    end

    def create(file_name:, file_path:, version_note:, extracted_text: nil)
      entity = Domain::Resume.new(
        id: @next_id, file_name: file_name, file_path: file_path,
        version_note: version_note, extracted_text: extracted_text,
        date_uploaded: Time.current
      )
      @next_id += 1
      @rows << entity
      entity
    end
  end

  # Fulfills CoverLetterRepositoryPort with an in-memory store.
  class CoverLetterRepository
    include CoverLetterRepositoryPort

    attr_reader :rows

    def initialize
      @rows = []
      @next_id = 1
    end

    def find(id)
      @rows.find { |row| row.id == id.to_i } || raise(Errors::NotFound, "document #{id} not found")
    end

    def all
      @rows.reject(&:archived?)
    end

    def create(file_name:, file_path:, version_note:)
      entity = Domain::CoverLetter.new(
        id: @next_id, file_name: file_name, file_path: file_path,
        version_note: version_note, date_uploaded: Time.current
      )
      @next_id += 1
      @rows << entity
      entity
    end
  end

  # Fulfills ComparisonRepositoryPort with an in-memory store.
  class ComparisonRepository
    include ComparisonRepositoryPort

    attr_reader :rows

    def initialize
      @rows = []
      @next_id = 1
    end

    def create(resume_id:, job_listing_id:, match_score:, resume_suggestions:)
      entity = Domain::ComparisonResult.new(
        id: @next_id, resume_id: resume_id, job_listing_id: job_listing_id,
        match_score: match_score, resume_suggestions: resume_suggestions,
        comparison_datetime: Time.current
      )
      @next_id += 1
      @rows << entity
      entity
    end
  end

  # Fulfills TrackingRepositoryPort with an in-memory store.
  class TrackingRepository
    include TrackingRepositoryPort

    attr_reader :rows

    def initialize
      @rows = []
      @next_id = 1
    end

    def all
      @rows.sort_by(&:id).reverse
    end

    def find(id)
      @rows.find { |row| row.id == id } || raise(Errors::NotFound, "tracking #{id} not found")
    end

    def create(job_listing_id:, resume_id:, comparison_id:, cover_letter_id:)
      entity = Domain::TrackingEntry.new(
        id: @next_id, job_listing_id: job_listing_id, resume_id: resume_id,
        comparison_id: comparison_id, cover_letter_id: cover_letter_id
      )
      @next_id += 1
      @rows << entity
      entity
    end

    def update(id:, changed_fields:)
      index = @rows.index { |row| row.id == id }
      @rows[index] = @rows[index].with(**changed_fields)
      @rows[index]
    end

    def update_many(changes:)
      changes.map { |change| update(id: change[:id], changed_fields: change[:changed_fields]) }
    end
  end

  # Fulfills ConfigRepositoryPort with a single in-memory row.
  class ConfigRepository
    include ConfigRepositoryPort

    def initialize(local_app_data: "/localAppData/resume", delimiter: "@@@startdelim@@@", compare_prompt: "Score honestly.")
      @config = Domain::AppConfig.new(
        id: 1, local_app_data: local_app_data, delimiter: delimiter, compare_prompt: compare_prompt
      )
    end

    def current
      @config
    end

    def update(**fields)
      @config = @config.with(**fields)
    end
  end

  # Fulfills MatchAnalyzerPort. Returns a canned raw reply and records the prompt.
  class MatchAnalyzer
    include MatchAnalyzerPort

    attr_reader :last_prompt

    def initialize(raw:)
      @raw = raw
      @last_prompt = nil
    end

    def analyze(prompt:)
      @last_prompt = prompt
      @raw
    end
  end

  # Fulfills ResumeRewriterPort. Echoes a canned rewrite.
  class ResumeRewriter
    include ResumeRewriterPort

    def initialize(rewritten: "REWRITTEN")
      @rewritten = rewritten
    end

    def rewrite(resume_text:, instructions:)
      "#{@rewritten}: #{instructions}"
    end
  end

  # Fulfills FileStoragePort. Records writes, returns the relative file_path.
  class FileStorage
    include FileStoragePort

    attr_reader :stored

    def initialize
      @stored = []
    end

    def store(file_name:, bytes:, directory:)
      @stored << { file_name: file_name, bytes: bytes, directory: directory }
      file_name
    end

    def read(file_path:, directory:)
      entry = @stored.find { |s| s[:file_name] == file_path && s[:directory] == directory }
      raise Errors::NotFound, "#{file_path} is no longer on disk" if entry.nil?

      entry[:bytes]
    end
  end

  # Fulfills UnitOfWorkPort. Just yields (no real transaction).
  class UnitOfWork
    include UnitOfWorkPort

    def transaction
      yield
    end
  end
end
