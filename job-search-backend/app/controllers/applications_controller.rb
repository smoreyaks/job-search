class ApplicationsController < ApplicationController
  # POST /applications/save
  # Writes the comparison and tracking rows in one transaction (Save All).
  def create
    result = Container.save_application.call(
      resume_id: params.require(:resume_id),
      job_listing_id: params.require(:job_listing_id),
      cover_letter_id: params.require(:cover_letter_id),
      match_score: params.require(:match_score),
      resume_suggestions: params[:resume_suggestions]
    )

    render json: {
      comparison: result[:comparison].to_h,
      tracking: result[:tracking].to_h
    }, status: :created
  end
end
