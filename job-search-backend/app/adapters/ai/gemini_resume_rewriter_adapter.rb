# Fulfills ResumeRewriterPort against Gemini (the Modify feature). Builds a
# rewrite prompt from the free-text instructions plus the resume, and returns
# the rewritten text.
class GeminiResumeRewriterAdapter
  include ResumeRewriterPort

  PREAMBLE = <<~TEXT.freeze
    You are tailoring a resume. Rewrite the resume text below following the
    instructions. Return only the rewritten resume text, with no preamble.
  TEXT

  def initialize(client: GeminiClient.new)
    @client = client
  end

  def rewrite(resume_text:, instructions:)
    prompt = "#{PREAMBLE}\nINSTRUCTIONS:\n#{instructions}\n\nRESUME:\n#{resume_text}"
    @client.generate(prompt)
  end
end
