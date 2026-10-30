require "rails_helper"

RSpec.describe UseCases::UploadResume do
  subject(:use_case) { described_class.new(resumes: resumes, file_storage: storage, config: config) }

  let(:resumes) { Fakes::ResumeRepository.new }
  let(:storage) { Fakes::FileStorage.new }
  let(:config)  { Fakes::ConfigRepository.new(local_app_data: "/data/resumes") }

  it "validates PDF, stores the bytes under localAppData, and records the row" do
    resume = use_case.call(file_name: "cv.pdf", bytes: "%PDF-1.7 ...",
                           version_note: "tailored for Mable", extracted_text: "plain text")

    expect(resume).to be_a(Domain::Resume)
    expect(resume.extracted_text).to eq("plain text")
    expect(resume.file_path).to eq("cv.pdf")
    expect(storage.stored.first).to include(file_name: "cv.pdf", directory: "/data/resumes")
    expect(resumes.rows.size).to eq(1)
  end

  it "rejects a non-PDF upload" do
    expect { use_case.call(file_name: "cv.docx", bytes: "not a pdf") }
      .to raise_error(Errors::ValidationFailed, /PDF/)
  end

  it "defaults a blank version note to N/A" do
    resume = use_case.call(file_name: "cv.pdf", bytes: "%PDF", version_note: "")

    expect(resume.version_note).to eq("N/A")
  end
end
