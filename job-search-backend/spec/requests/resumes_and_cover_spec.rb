require "rails_helper"
require "tmpdir"

RSpec.describe "Resumes and cover letters", type: :request do
  def pdf_upload
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.pdf"), "application/pdf")
  end

  describe "GET /resumes/savedList" do
    it "returns saved resumes" do
      create_resume(file_name: "a.pdf", file_path: "a.pdf")

      get "/resumes/savedList"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
    end
  end

  describe "POST /resume/upload" do
    it "stores the PDF under localAppData and records the row" do
      dir = Dir.mktmpdir
      seed_config(local_app_data: dir)

      post "/resume/upload", params: {
        file: pdf_upload, file_name: "sample.pdf", version_note: "v1", extracted_text: "resume text"
      }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["extracted_text"]).to eq("resume text")
      expect(File).to exist(File.join(dir, "sample.pdf"))
    end

    it "returns 422 when no file is provided" do
      seed_config

      post "/resume/upload", params: { version_note: "v1" }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /cover/savedList" do
    it "returns saved cover letters" do
      create_cover_letter(file_name: "a.pdf", file_path: "a.pdf")

      get "/cover/savedList"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
    end
  end

  describe "POST /cover/upload" do
    it "stores the cover letter PDF and records the row" do
      dir = Dir.mktmpdir
      seed_config(local_app_data: dir)

      post "/cover/upload", params: { file: pdf_upload, file_name: "cl.pdf", version_note: "v1" }

      expect(response).to have_http_status(:created)
      expect(File).to exist(File.join(dir, "cl.pdf"))
    end
  end

  describe "GET /resumes/:id/file and /cover/:id/file" do
    it "serves the stored resume PDF inline" do
      dir = Dir.mktmpdir
      seed_config(local_app_data: dir)
      post "/resume/upload", params: { file: pdf_upload, file_name: "sample.pdf", version_note: "v1", extracted_text: "t" }
      id = response.parsed_body["id"]

      get "/resumes/#{id}/file"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to start_with("inline")
      expect(response.body.b).to eq(File.binread(Rails.root.join("spec/fixtures/files/sample.pdf")))
    end

    it "serves the stored cover letter PDF" do
      dir = Dir.mktmpdir
      seed_config(local_app_data: dir)
      post "/cover/upload", params: { file: pdf_upload, file_name: "cover.pdf", version_note: "v1" }

      get "/cover/#{response.parsed_body["id"]}/file"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end

    it "returns 404 with a message when the file has gone from disk" do
      seed_config(local_app_data: Dir.mktmpdir)
      resume = create_resume(file_name: "a.pdf", file_path: "a.pdf")

      get "/resumes/#{resume.id}/file"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to match(/a\.pdf is no longer in/)
    end
  end
end
