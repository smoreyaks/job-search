module Domain
  # Whitelists the editable tracking fields and normalizes their values (dates
  # parsed/validated, booleans coerced). Shared by the row-save and save-all use
  # cases so both enforce the same rules. Raises Errors::ValidationFailed on a
  # bad date; silently drops any non-editable field.
  class TrackingFieldSanitizer
    EDITABLE_FIELDS = %i[
      applied date_applied response_received follow_up_needed
      interview_date notes next_follow_up_date
    ].freeze
    DATE_FIELDS = %i[date_applied interview_date next_follow_up_date].freeze
    BOOLEAN_FIELDS = %i[applied response_received follow_up_needed].freeze
    TRUTHY = [true, "true", 1, "1"].freeze

    def sanitize(changed_fields)
      symbolized = changed_fields.to_h.transform_keys(&:to_sym)
      symbolized.slice(*EDITABLE_FIELDS).each_with_object({}) do |(key, value), result|
        result[key] = normalize(key, value)
      end
    end

    private

    def normalize(key, value)
      return normalize_date(key, value) if DATE_FIELDS.include?(key)
      return TRUTHY.include?(value) if BOOLEAN_FIELDS.include?(key)

      value
    end

    def normalize_date(key, value)
      return nil if value.nil? || value == ""
      return value if value.is_a?(Date)

      Date.iso8601(value.to_s)
    rescue ArgumentError, TypeError
      raise Errors::ValidationFailed, "invalid date for #{key}: #{value.inspect}"
    end
  end
end
