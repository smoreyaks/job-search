require "rails_helper"

RSpec.describe UseCases::ReadDocumentFile do
  subject(:use_case) { described_class.new(documents: documents, file_storage: storage, config: config) }

  let(:documents) { Fakes::ResumeRepository.new }
  let(:storage) { Fakes::FileStorage.new }
  let(:config) { Fakes::ConfigRepository.new(local_app_data: "/data/resumes") }

  it "returns the stored PDF for a document, read from localAppData" do
    storage.store(file_name: "cv.pdf", bytes: "%PDF-1.7 cv", directory: "/data/resumes")
    resume = documents.create(file_name: "My CV.pdf", file_path: "cv.pdf", version_note: "v1")

    expect(use_case.call(id: resume.id)).to eq(file_name: "My CV.pdf", bytes: "%PDF-1.7 cv")
  end

  it "raises NotFound for an unknown document" do
    expect { use_case.call(id: 99) }.to raise_error(Errors::NotFound)
  end

  it "raises NotFound when the file is no longer on disk" do
    resume = documents.create(file_name: "gone.pdf", file_path: "gone.pdf", version_note: "v1")

    expect { use_case.call(id: resume.id) }.to raise_error(Errors::NotFound, /gone\.pdf/)
  end
end
