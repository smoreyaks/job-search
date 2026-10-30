require "rails_helper"

RSpec.describe ActiveRecordTransactionAdapter do
  subject(:adapter) { described_class.new }

  it "honors the UnitOfWorkPort contract" do
    expect(adapter).to be_a(UnitOfWorkPort)
  end

  it "returns the block's value" do
    expect(adapter.transaction { 42 }).to eq(42)
  end

  it "rolls back all writes when the block raises" do
    expect do
      adapter.transaction do
        Config.create!(local_app_data: "/x", delimiter: "@@@startdelim@@@")
        raise "boom"
      end
    end.to raise_error("boom")

    expect(Config.count).to eq(0)
  end
end
