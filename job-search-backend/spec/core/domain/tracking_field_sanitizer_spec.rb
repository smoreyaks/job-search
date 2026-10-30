require "rails_helper"

RSpec.describe Domain::TrackingFieldSanitizer do
  subject(:sanitizer) { described_class.new }

  it "keeps only editable fields and drops the rest" do
    result = sanitizer.sanitize(applied: true, notes: "hi", id: 99, job_listing_id: 5, garbage: "x")

    expect(result.keys).to contain_exactly(:applied, :notes)
  end

  it "accepts string keys" do
    result = sanitizer.sanitize("applied" => "true", "notes" => "hello")

    expect(result).to eq(applied: true, notes: "hello")
  end

  it "coerces boolean fields" do
    result = sanitizer.sanitize(applied: "true", response_received: false, follow_up_needed: "1")

    expect(result).to eq(applied: true, response_received: false, follow_up_needed: true)
  end

  it "parses ISO date strings into Date" do
    result = sanitizer.sanitize(date_applied: "2026-10-20")

    expect(result[:date_applied]).to eq(Date.new(2026, 10, 20))
  end

  it "treats a blank date as nil" do
    expect(sanitizer.sanitize(interview_date: "")).to eq(interview_date: nil)
  end

  it "raises on an invalid date" do
    expect { sanitizer.sanitize(next_follow_up_date: "not-a-date") }
      .to raise_error(Errors::ValidationFailed, /invalid date/)
  end
end
