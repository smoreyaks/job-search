module UseCases
  # Pure compute, no DB write. Sends resume text plus free-text guidance to the
  # AI and returns the rewritten text. The HTTP route for this is NOT mapped in
  # the PRD yet (Modify is extended scope), so no controller wires it up for now;
  # the use case is built and tested so it is ready when the route is decided.
  class ModifyResume
    def initialize(rewriter:)
      @rewriter = rewriter
    end

    def call(resume_text:, instructions:)
      raise Errors::ValidationFailed, "resume text is required" if resume_text.to_s.strip.empty?
      raise Errors::ValidationFailed, "instructions are required" if instructions.to_s.strip.empty?

      @rewriter.rewrite(resume_text: resume_text, instructions: instructions)
    end
  end
end
