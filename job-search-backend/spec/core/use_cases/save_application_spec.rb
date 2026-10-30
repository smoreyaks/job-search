require "rails_helper"

RSpec.describe UseCases::SaveApplication do
  subject(:use_case) do
    described_class.new(comparisons: comparisons, tracking: tracking, unit_of_work: Fakes::UnitOfWork.new)
  end

  let(:comparisons) { Fakes::ComparisonRepository.new }
  let(:tracking)    { Fakes::TrackingRepository.new }

  it "writes a comparison and a tracking row linked by comparison_id" do
    result = use_case.call(resume_id: 1, job_listing_id: 2, cover_letter_id: 3,
                           match_score: 82, resume_suggestions: "gaps here")

    expect(comparisons.rows.size).to eq(1)
    expect(tracking.rows.size).to eq(1)

    expect(result[:comparison]).to be_a(Domain::ComparisonResult)
    expect(result[:tracking]).to be_a(Domain::TrackingEntry)
    expect(result[:tracking].comparison_id).to eq(result[:comparison].id)
    expect(result[:tracking].cover_letter_id).to eq(3)
  end

  it "runs inside the unit of work" do
    uow = instance_spy(Fakes::UnitOfWork)
    allow(uow).to receive(:transaction).and_yield
    described_class.new(comparisons: comparisons, tracking: tracking, unit_of_work: uow)
      .call(resume_id: 1, job_listing_id: 2, cover_letter_id: 3, match_score: 50, resume_suggestions: "x")

    expect(uow).to have_received(:transaction)
  end
end
