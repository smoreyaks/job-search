require "rails_helper"

RSpec.describe UseCases::SearchJobs do
  subject(:use_case) { described_class.new(job_sources: { "jsearch" => job_source, "jobs_api" => jobs_api }) }

  let(:job_source) { Fakes::JobSource.new(results: %w[result1 result2]) }
  let(:jobs_api) { Fakes::JobSource.new(results: %w[linkedin1]) }

  it "delegates to the job source and returns its results" do
    result = use_case.call(keyword: "ruby", location: "Sydney", remote: true, job_type: "full-time", count: 30)

    expect(result).to eq(%w[result1 result2])
    expect(job_source.last_args).to eq(
      keyword: "ruby", location: "Sydney", remote: true, job_type: "full-time", count: 30
    )
  end

  it "requires a keyword" do
    expect { use_case.call(keyword: "   ") }.to raise_error(Errors::ValidationFailed, /keyword/)
  end

  it "coerces remote to a boolean" do
    use_case.call(keyword: "ruby", remote: nil)

    expect(job_source.last_args[:remote]).to eq(false)
  end

  it "falls back to the default count when an unsupported count is given" do
    use_case.call(keyword: "ruby", count: 25)

    expect(job_source.last_args[:count]).to eq(10)
  end

  it "rejects an invalid job_type" do
    expect { use_case.call(keyword: "ruby", job_type: "freelance") }
      .to raise_error(Errors::ValidationFailed, /job_type/)
  end

  it "allows a single result" do
    use_case.call(keyword: "ruby", count: 1)

    expect(job_source.last_args[:count]).to eq(1)
  end

  it "uses JSearch when no source is given" do
    use_case.call(keyword: "ruby")

    expect(job_source.last_args).to be_present
    expect(jobs_api.last_args).to be_nil
  end

  it "searches the source the user picked" do
    result = use_case.call(keyword: "ruby", location: "Sydney", source: "jobs_api")

    expect(result).to eq(%w[linkedin1])
    expect(jobs_api.last_args).to include(keyword: "ruby", location: "Sydney")
    expect(job_source.last_args).to be_nil
  end

  it "rejects an unknown source" do
    expect { use_case.call(keyword: "ruby", source: "monster") }
      .to raise_error(Errors::ValidationFailed, /source/)
  end
end
