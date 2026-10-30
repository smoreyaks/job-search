require "rails_helper"

RSpec.describe ResumeDatabaseAdapter do
  subject(:adapter) { described_class.new }

  it "honors the ResumeRepositoryPort contract" do
    expect(adapter).to be_a(ResumeRepositoryPort)
  end

  describe "#create" do
    it "persists and returns a Domain::Resume with id and date_uploaded" do
      resume = adapter.create(file_name: "cv.pdf", file_path: "/x/cv.pdf",
                              version_note: "v1", extracted_text: "hello world")

      expect(Resume.count).to eq(1)
      expect(resume).to be_a(Domain::Resume)
      expect(resume.id).to be_present
      expect(resume.date_uploaded).to be_present
      expect(resume.version_note).to eq("v1")
      expect(resume.extracted_text).to eq("hello world")
    end

    it "defaults extracted_text to nil when not provided" do
      resume = adapter.create(file_name: "cv.pdf", file_path: "/x/cv.pdf", version_note: "v1")

      expect(resume.extracted_text).to be_nil
    end
  end

  describe "#all" do
    it "returns non-archived resumes as entities, most recent first" do
      older = adapter.create(file_name: "old.pdf", file_path: "/x/old.pdf", version_note: "v1")
      newer = adapter.create(file_name: "new.pdf", file_path: "/x/new.pdf", version_note: "v2")

      result = adapter.all

      expect(result).to all(be_a(Domain::Resume))
      expect(result.map(&:id)).to eq([newer.id, older.id])
    end

    it "excludes archived resumes" do
      kept = adapter.create(file_name: "keep.pdf", file_path: "/x/keep.pdf", version_note: "v1")
      gone = adapter.create(file_name: "gone.pdf", file_path: "/x/gone.pdf", version_note: "v1")
      Resume.find(gone.id).update!(archived_at: Time.current)

      expect(adapter.all.map(&:id)).to eq([kept.id])
    end
  end
end
