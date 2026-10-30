require "rails_helper"

RSpec.describe ConfigDatabaseAdapter do
  subject(:adapter) { described_class.new }

  before do
    Config.create!(local_app_data: "/localAppData/resume", delimiter: "@@@startdelim@@@")
  end

  it "honors the ConfigRepositoryPort contract" do
    expect(adapter).to be_a(ConfigRepositoryPort)
  end

  describe "#current" do
    it "returns the single config row as a Domain::AppConfig" do
      cfg = adapter.current

      expect(cfg).to be_a(Domain::AppConfig)
      expect(cfg.local_app_data).to eq("/localAppData/resume")
      expect(cfg.delimiter).to eq("@@@startdelim@@@")
      expect(cfg.compare_prompt).to be_nil
    end
  end

  describe "#update" do
    it "updates the given fields and returns the updated entity" do
      cfg = adapter.update(local_app_data: "/new/path", compare_prompt: "score it honestly")

      expect(cfg.local_app_data).to eq("/new/path")
      expect(cfg.compare_prompt).to eq("score it honestly")
      expect(Config.first.local_app_data).to eq("/new/path")
    end
  end
end
