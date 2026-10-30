# Fulfills MatchAnalyzerPort against Gemini. Core builds the full prompt
# (ComparePromptBuilder); this just sends it and returns the raw delimited text.
class GeminiMatchAnalyzerAdapter
  include MatchAnalyzerPort

  def initialize(client: GeminiClient.new)
    @client = client
  end

  def analyze(prompt:)
    @client.generate(prompt)
  end
end
