require "rails_helper"

RSpec.describe UseCases::CompareResumeToJob do
  subject(:use_case) { described_class.new(analyzer: analyzer, config: config) }

  let(:config) { Fakes::ConfigRepository.new(delimiter: "@@@startdelim@@@", compare_prompt: "Be honest.") }
  let(:analyzer) do
    Fakes::MatchAnalyzer.new(
      raw: "@@@startdelim@@@82@@@enddelim@@@ @@@startdelim@@@Missing Kubernetes and AWS.@@@enddelim@@@"
    )
  end
  let(:job) do
    Domain::JobListing.new(board_source: "seek", company: "Acme", job_title: "Dev",
                           job_posted_date: Date.new(2026, 10, 1), employment_type: "full-time",
                           job_description: "d", url: "https://x/1")
  end

  it "builds a prompt, parses the delimited reply into score + analysis" do
    result = use_case.call(resume_text: "my resume text", job_listing: job)

    expect(result).to be_a(Domain::ComparisonResult)
    expect(result.match_score).to eq(82.0)
    expect(result.resume_suggestions).to eq("Missing Kubernetes and AWS.")
    expect(result.id).to be_nil # pure compute, not persisted
  end

  it "passes the built prompt (instructions + resume + job) to the analyzer" do
    use_case.call(resume_text: "my resume text", job_listing: job)

    expect(analyzer.last_prompt).to include("Be honest.", "my resume text", "job_title: Dev")
  end

  it "requires resume text" do
    expect { use_case.call(resume_text: "  ", job_listing: job) }
      .to raise_error(Errors::ValidationFailed, /resume text/)
  end

  it "defaults to a 0.0 score when the reply has no parseable number" do
    bad = described_class.new(
      analyzer: Fakes::MatchAnalyzer.new(raw: "@@@startdelim@@@n/a@@@enddelim@@@ @@@startdelim@@@text@@@enddelim@@@"),
      config: config
    )

    expect(bad.call(resume_text: "r", job_listing: job).match_score).to eq(0.0)
  end
end
