module UnitOfWorkPort
  # Wraps the given block in an all-or-nothing transaction.
  # Core calls this without knowing about ActiveRecord.
  def transaction(&block)
    raise NotImplementedError, "#{self.class}#transaction not implemented"
  end
end
