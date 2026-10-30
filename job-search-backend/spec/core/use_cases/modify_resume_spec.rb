require "rails_helper"

RSpec.describe UseCases::ModifyResume do
  subject(:use_case) { described_class.new(rewriter: Fakes::ResumeRewriter.new(rewritten: "NEW")) }

  it "returns the AI-rewritten text" do
    result = use_case.call(resume_text: "old resume", instructions: "make it concise")

    expect(result).to eq("NEW: make it concise")
  end

  it "requires resume text" do
    expect { use_case.call(resume_text: "", instructions: "x") }
      .to raise_error(Errors::ValidationFailed, /resume text/)
  end

  it "requires instructions" do
    expect { use_case.call(resume_text: "r", instructions: "  ") }
      .to raise_error(Errors::ValidationFailed, /instructions/)
  end
end
