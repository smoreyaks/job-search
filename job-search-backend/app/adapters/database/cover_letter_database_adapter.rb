# ActiveRecord-backed implementation of CoverLetterRepositoryPort.
# Maps between the CoverLetter AR model (table cover_table) and the
# Domain::CoverLetter entity. Mirrors ResumeDatabaseAdapter without extracted_text.
class CoverLetterDatabaseAdapter
  include CoverLetterRepositoryPort

  # All non-archived cover letters, most recent first.
  def all
    CoverLetter.not_archived.most_recent_first.map { |record| to_entity(record) }
  end

  # Creates a cover letter row.
  def create(file_name:, file_path:, version_note:)
    record = CoverLetter.create!(
      file_name: file_name,
      file_path: file_path,
      version_note: version_note
    ).reload # reload picks up the DB-defaulted date_uploaded
    to_entity(record)
  end

  def find(id)
    record = CoverLetter.find_by(id: id)
    raise Errors::NotFound, "cover letter #{id} not found" if record.nil?

    to_entity(record)
  end

  private

  MEMBERS = Domain::CoverLetter.members.freeze

  def to_entity(record)
    Domain::CoverLetter.new(**record.attributes.symbolize_keys.slice(*MEMBERS))
  end
end
