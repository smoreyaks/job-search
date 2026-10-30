require "rails_helper"

RSpec.describe CoverLetterDatabaseAdapter do
  subject(:adapter) { described_class.new }

  it "honors the CoverLetterRepositoryPort contract" do
    expect(adapter).to be_a(CoverLetterRepositoryPort)
  end

  describe "#create" do
    it "persists and returns a Domain::CoverLetter with id and date_uploaded" do
      cover = adapter.create(file_name: "cl.pdf", file_path: "/x/cl.pdf", version_note: "v1")

      expect(CoverLetter.count).to eq(1)
      expect(cover).to be_a(Domain::CoverLetter)
      expect(cover.id).to be_present
      expect(cover.date_uploaded).to be_present
      expect(cover.version_note).to eq("v1")
    end
  end

  describe "#all" do
    it "returns non-archived cover letters as entities, most recent first" do
      older = adapter.create(file_name: "old.pdf", file_path: "/x/old.pdf", version_note: "v1")
      newer = adapter.create(file_name: "new.pdf", file_path: "/x/new.pdf", version_note: "v2")

      result = adapter.all

      expect(result).to all(be_a(Domain::CoverLetter))
      expect(result.map(&:id)).to eq([newer.id, older.id])
    end

    it "excludes archived cover letters" do
      kept = adapter.create(file_name: "keep.pdf", file_path: "/x/keep.pdf", version_note: "v1")
      gone = adapter.create(file_name: "gone.pdf", file_path: "/x/gone.pdf", version_note: "v1")
      CoverLetter.find(gone.id).update!(archived_at: Time.current)

      expect(adapter.all.map(&:id)).to eq([kept.id])
    end
  end
end
