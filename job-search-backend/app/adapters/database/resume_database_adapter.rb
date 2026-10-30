# ActiveRecord-backed implementation of ResumeRepositoryPort.
# Maps between the Resume AR model and the Domain::Resume entity.
class ResumeDatabaseAdapter
  include ResumeRepositoryPort

  # All non-archived resumes, most recent first.
  def all
    Resume.not_archived.most_recent_first.map { |record| to_entity(record) }
  end

  # Creates a resume row. extracted_text comes from pdf.js at upload time.
  def create(file_name:, file_path:, version_note:, extracted_text: nil)
    record = Resume.create!(
      file_name: file_name,
      file_path: file_path,
      version_note: version_note,
      extracted_text: extracted_text
    ).reload # reload picks up the DB-defaulted date_uploaded
    to_entity(record)
  end

  def find(id)
    record = Resume.find_by(id: id)
    raise Errors::NotFound, "resume #{id} not found" if record.nil?

    to_entity(record)
  end

  private

  MEMBERS = Domain::Resume.members.freeze

  def to_entity(record)
    Domain::Resume.new(**record.attributes.symbolize_keys.slice(*MEMBERS))
  end
end
