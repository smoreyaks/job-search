require "rails_helper"

RSpec.describe UseCases::UploadCoverLetter do
  subject(:use_case) { described_class.new(cover_letters: covers, file_storage: storage, config: config) }

  let(:covers)  { Fakes::CoverLetterRepository.new }
  let(:storage) { Fakes::FileStorage.new }
  let(:config)  { Fakes::ConfigRepository.new(local_app_data: "/data/covers") }

  it "validates PDF, stores the bytes, and records the row" do
    cover = use_case.call(file_name: "cl.pdf", bytes: "%PDF-1.7", version_note: "v1")

    expect(cover).to be_a(Domain::CoverLetter)
    expect(cover.file_path).to eq("cl.pdf")
    expect(storage.stored.first).to include(file_name: "cl.pdf", directory: "/data/covers")
    expect(covers.rows.size).to eq(1)
  end

  it "rejects a non-PDF upload" do
    expect { use_case.call(file_name: "cl.txt", bytes: "nope") }
      .to raise_error(Errors::ValidationFailed, /PDF/)
  end
end
