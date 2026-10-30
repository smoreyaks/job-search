# ActiveRecord-backed implementation of ConfigRepositoryPort.
# Maps between the Config AR model (single-row table config) and the
# Domain::AppConfig entity.
class ConfigDatabaseAdapter
  include ConfigRepositoryPort

  # The single config row.
  def current
    record = Config.first
    raise ActiveRecord::RecordNotFound, "config row not seeded" if record.nil?

    to_entity(record)
  end

  # Updates any subset of config fields and returns the updated entity.
  # Accepts local_app_data:, delimiter:, compare_prompt:
  def update(**fields)
    record = Config.first
    raise ActiveRecord::RecordNotFound, "config row not seeded" if record.nil?

    record.update!(fields)
    to_entity(record)
  end

  private

  MEMBERS = Domain::AppConfig.members.freeze

  def to_entity(record)
    Domain::AppConfig.new(**record.attributes.symbolize_keys.slice(*MEMBERS))
  end
end
