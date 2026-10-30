module ResumeRewriterPort
  # Sends resume text and free-text instructions to the AI and returns the
  # rewritten resume text. Pure compute, no DB write.
  # resume_text: String, instructions: String
  def rewrite(resume_text:, instructions:)
    raise NotImplementedError, "#{self.class}#rewrite not implemented"
  end
end
