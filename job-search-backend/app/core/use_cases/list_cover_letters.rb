module UseCases
  # Returns all non-archived cover letters, most recent first.
  class ListCoverLetters
    def initialize(repository:)
      @repository = repository
    end

    def call
      @repository.all
    end
  end
end
