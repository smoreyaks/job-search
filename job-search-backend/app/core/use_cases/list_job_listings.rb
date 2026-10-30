module UseCases
  # Returns all saved (non-archived) job listings, newest first.
  class ListJobListings
    def initialize(repository:)
      @repository = repository
    end

    def call
      @repository.all
    end
  end
end
