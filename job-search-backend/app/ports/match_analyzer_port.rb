module MatchAnalyzerPort
  # Sends an already-built prompt to the AI and returns its raw text reply.
  # Prompt construction (instructions + resume text + job data + delimiters)
  # lives in core (Domain::ComparePromptBuilder); the adapter only talks to the
  # AI and hands back the raw delimited string for core to parse.
  def analyze(prompt:)
    raise NotImplementedError, "#{self.class}#analyze not implemented"
  end
end
