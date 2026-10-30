require "rails_helper"

RSpec.describe Domain::ComparePromptBuilder do
  subject(:builder) { described_class.new }

  let(:job) do
    Domain::JobListing.new(board_source: "seek", company: "Acme", job_title: "Ruby Dev",
                           location: "Sydney", job_posted_date: Date.new(2026, 10, 1),
                           employment_type: "full-time", job_description: "Build things",
                           url: "https://seek.com/1")
  end

  it "orders the prompt as instructions, then resume, then job, with delimiters" do
    prompt = builder.build(instructions: "Score it.", resume_text: "my resume",
                           job_listing: job, start_marker: "@@@startdelim@@@", end_marker: "@@@enddelim@@@")

    expect(prompt).to start_with("Score it.")
    expect(prompt.index("my resume")).to be < prompt.index("company: Acme")
    expect(prompt).to include("@@@startdelim@@@", "@@@enddelim@@@")
  end

  it "renders the key job fields" do
    prompt = builder.build(instructions: "", resume_text: "r", job_listing: job,
                           start_marker: "<s>", end_marker: "<e>")

    expect(prompt).to include("job_title: Ruby Dev", "employment_type: full-time", "location: Sydney")
  end

  it "accepts a plain hash as the job listing" do
    prompt = builder.build(instructions: "", resume_text: "r",
                           job_listing: { company: "Globex", job_title: "Eng" },
                           start_marker: "<s>", end_marker: "<e>")

    expect(prompt).to include("company: Globex", "job_title: Eng")
  end
end
