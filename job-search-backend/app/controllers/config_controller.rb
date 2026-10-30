class ConfigController < ApplicationController
  # GET /config
  def show
    render_entity(Container.get_config.call)
  end

  # PATCH /config/saveAll  { local_app_data:, delimiter:, compare_prompt: }
  def save_all
    cfg = Container.update_config.call(**config_params)
    render_entity(cfg)
  end

  private

  def config_params
    params.permit(:local_app_data, :delimiter, :compare_prompt).to_h.symbolize_keys
  end
end
