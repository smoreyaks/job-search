class ResumesController < ApplicationController
  # GET /resumes/savedList
  def saved_list
    render_collection(Container.list_resumes.call)
  end

  # POST /resume/upload  (multipart: file + version_note + extracted_text)
  def upload
    file = params.require(:file)
    resume = Container.upload_resume.call(
      file_name: params[:file_name].presence || file.original_filename,
      bytes: file.read,
      version_note: params[:version_note].to_s,
      extracted_text: params[:extracted_text]
    )
    render_entity(resume, status: :created)
  end

  # GET /resumes/:id/file  (the stored PDF, for the Edit page viewer)
  def file
    document = Container.read_resume_file.call(id: params[:id])
    send_data document[:bytes], type: "application/pdf", filename: document[:file_name], disposition: "inline"
  end
end
