class ApplicationController < ActionController::API
  # Core errors and their ActiveRecord equivalents mapped to HTTP status in one
  # place, per the PRD's "mapped to HTTP status in one place".
  rescue_from Errors::ValidationFailed, with: :render_unprocessable
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_unprocessable
  rescue_from Errors::NotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from Errors::ExternalServiceFailed, with: :render_bad_gateway

  private

  # Domain entities are Data objects; to_h gives a JSON-ready hash.
  def render_entity(entity, status: :ok)
    render json: entity.to_h, status: status
  end

  def render_collection(entities, status: :ok)
    render json: entities.map(&:to_h), status: status
  end

  def render_unprocessable(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def render_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def render_bad_gateway(error)
    render json: { error: error.message }, status: :bad_gateway
  end
end
