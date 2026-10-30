class CoverController < ApplicationController
  # GET /cover/savedList
  def saved_list
    render_collection(Container.list_cover_letters.call)
  end

  # POST /cover/upload  (multipart: file + version_note)
  def upload
    file = params.require(:file)
    cover = Container.upload_cover_letter.call(
      file_name: params[:file_name].presence || file.original_filename,
      bytes: file.read,
      version_note: params[:version_note].to_s
    )
    render_entity(cover, status: :created)
  end

  # GET /cover/:id/file  (the stored PDF, for the Edit page viewer)
  def file
    document = Container.read_cover_letter_file.call(id: params[:id])
    send_data document[:bytes], type: "application/pdf", filename: document[:file_name], disposition: "inline"
  end
end
