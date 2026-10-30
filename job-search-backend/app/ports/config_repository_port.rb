module ConfigRepositoryPort
  # Returns the single config entity.
  def current
    raise NotImplementedError, "#{self.class}#current not implemented"
  end

  # Updates config fields and returns the updated entity.
  # Accepts any combination of: local_app_data:, delimiter:, compare_prompt:
  def update(**fields)
    raise NotImplementedError, "#{self.class}#update not implemented"
  end
end
