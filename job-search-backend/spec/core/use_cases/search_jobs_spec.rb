require "rails_helper"

RSpec.describe UseCases::SearchJobs do
  subject(:use_case) { described_class.new(job_source: job_source) }

  let(:job_source) { Fakes::JobSource.new(results: %w[result1 result2]) }

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
end
