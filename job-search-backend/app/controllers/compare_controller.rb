class CompareController < ApplicationController
  LISTING_KEYS = Domain::JobListing.members

  # POST /compare  { resume_text:, job_listing: {...} }
  def create
    result = Container.compare_resume_to_job.call(
      resume_text: params[:resume_text],
      job_listing: job_listing_params
    )
    render_entity(result)
  end

  private

  def job_listing_params
    params.permit(job_listing: LISTING_KEYS).fetch(:job_listing, {}).to_h.symbolize_keys
  end
end
