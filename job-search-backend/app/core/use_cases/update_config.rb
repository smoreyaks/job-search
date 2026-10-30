module UseCases
  # Save config (PATCH /config/saveAll): updates any subset of the config fields
  # sent together in one body (localAppData path, Gemini delimiter, Compare
  # prompt). Validates that localAppData, if given, is not blank.
  class UpdateConfig
    ALLOWED_FIELDS = %i[local_app_data delimiter compare_prompt].freeze

    def initialize(repository:)
      @repository = repository
    end

    def call(**fields)
      allowed = fields.transform_keys(&:to_sym).slice(*ALLOWED_FIELDS)
      raise Errors::ValidationFailed, "no config fields provided" if allowed.empty?

      if allowed.key?(:local_app_data) && allowed[:local_app_data].to_s.strip.empty?
        raise Errors::ValidationFailed, "local_app_data cannot be blank"
      end

      @repository.update(**allowed)
    end
  end
end
