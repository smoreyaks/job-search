module UseCases
  # Loads the single config row on app init (GET /config).
  class GetConfig
    def initialize(repository:)
      @repository = repository
    end

    def call
      @repository.current
    end
  end
end
