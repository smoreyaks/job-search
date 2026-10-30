module UseCases
  # Returns all tracking entries (the whole table, newest first). "Load more" is
  # a frontend display concern, not a route-level page.
  class ListTrackingEntries
    def initialize(repository:)
      @repository = repository
    end

    def call
      @repository.all
    end
  end
end
