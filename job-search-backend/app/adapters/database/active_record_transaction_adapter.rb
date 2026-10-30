# Implements UnitOfWorkPort by wrapping the block in an ActiveRecord
# transaction, so core use cases can request all-or-nothing writes without
# knowing about ActiveRecord.
class ActiveRecordTransactionAdapter
  include UnitOfWorkPort

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end
end
