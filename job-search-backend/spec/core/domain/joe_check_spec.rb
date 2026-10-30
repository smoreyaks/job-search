require "rails_helper"

RSpec.describe Domain::JoeCheck do
  let(:now) { Time.zone.parse("2026-10-20 12:00") }

  describe ".status_for" do
    it "is 1 (expired) once the expiry has passed and 0 (good) before it" do
      expect(described_class.status_for(now - 1.second, now: now)).to eq(1)
      expect(described_class.status_for(now + 1.second, now: now)).to eq(0)
    end

    it "reads JSearch's ISO-8601 strings" do
      expect(described_class.status_for("2026-10-19T00:00:00.000Z", now: now)).to eq(1)
    end

    it "is nil when there is no expiry or it can't be read" do
      expect(described_class.status_for(nil, now: now)).to be_nil
      expect(described_class.status_for("", now: now)).to be_nil
      expect(described_class.status_for("not a date", now: now)).to be_nil
    end
  end
end
