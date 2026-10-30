module UseCases
  # Returns all non-archived resumes, most recent first.
  class ListResumes
    def initialize(repository:)
      @repository = repository
    end

    def call
      @repository.all
    end
  end
end
