require "rails_helper"

RSpec.describe Domain::DelimitedResponseParser do
  subject(:parser) { described_class.new }

  it "extracts each start...end segment's inner content in order" do
    raw = "noise @@@startdelim@@@87@@@enddelim@@@ middle @@@startdelim@@@Strong match@@@enddelim@@@ tail"

    segments = parser.parse(raw, start_marker: "@@@startdelim@@@", end_marker: "@@@enddelim@@@")

    expect(segments).to eq(["87", "Strong match"])
  end

  it "handles multi-line content between the markers" do
    raw = "@@@startdelim@@@line one\nline two@@@enddelim@@@"

    segments = parser.parse(raw, start_marker: "@@@startdelim@@@", end_marker: "@@@enddelim@@@")

    expect(segments).to eq(["line one\nline two"])
  end

  it "returns an empty array when no markers are present" do
    expect(parser.parse("plain text", start_marker: "<s>", end_marker: "<e>")).to eq([])
  end
end
