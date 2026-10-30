require "rails_helper"

RSpec.describe "Config", type: :request do
  describe "GET /config" do
    it "returns the single config row" do
      seed_config(local_app_data: "/localAppData/resume")

      get "/config"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["local_app_data"]).to eq("/localAppData/resume")
    end
  end

  describe "PATCH /config/saveAll" do
    it "updates the config fields together" do
      seed_config

      patch "/config/saveAll", params: {
        local_app_data: "/new/path", delimiter: "@@@d@@@", compare_prompt: "score it"
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["local_app_data"]).to eq("/new/path")
      expect(response.parsed_body["compare_prompt"]).to eq("score it")
    end

    it "returns 422 when local_app_data is blank" do
      seed_config

      patch "/config/saveAll", params: { local_app_data: "   " }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
