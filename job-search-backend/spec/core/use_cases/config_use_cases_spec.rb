require "rails_helper"

RSpec.describe "Config use cases" do
  let(:repository) { Fakes::ConfigRepository.new(local_app_data: "/localAppData/resume") }

  describe UseCases::GetConfig do
    it "returns the single config row" do
      cfg = described_class.new(repository: repository).call

      expect(cfg).to be_a(Domain::AppConfig)
      expect(cfg.local_app_data).to eq("/localAppData/resume")
    end
  end

  describe UseCases::UpdateConfig do
    subject(:use_case) { described_class.new(repository: repository) }

    it "updates the given config fields together" do
      cfg = use_case.call(local_app_data: "/new/path", delimiter: "@@@d@@@", compare_prompt: "score it")

      expect(cfg.local_app_data).to eq("/new/path")
      expect(cfg.delimiter).to eq("@@@d@@@")
      expect(cfg.compare_prompt).to eq("score it")
    end

    it "ignores unknown fields" do
      cfg = use_case.call(compare_prompt: "x", hacker: "nope")

      expect(cfg.compare_prompt).to eq("x")
    end

    it "rejects an empty update" do
      expect { use_case.call(hacker: "nope") }.to raise_error(Errors::ValidationFailed, /no config fields/)
    end

    it "rejects a blank local_app_data" do
      expect { use_case.call(local_app_data: "   ") }.to raise_error(Errors::ValidationFailed, /local_app_data/)
    end
  end
end
