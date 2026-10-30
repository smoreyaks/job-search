require "rails_helper"

RSpec.describe "Gemini adapters" do
  def gemini_body(text)
    { "candidates" => [{ "content" => { "parts" => [{ "text" => text }] } }] }.to_json
  end

  describe GeminiMatchAnalyzerAdapter do
    subject(:adapter) { described_class.new(client: GeminiClient.new(api_key: "k")) }

    it "honors the MatchAnalyzerPort contract" do
      expect(adapter).to be_a(MatchAnalyzerPort)
    end

    it "sends the prompt and returns the model's text" do
      stub_request(:post, /generativelanguage\.googleapis\.com/).to_return(
        status: 200,
        body: gemini_body("@@@startdelim@@@82@@@enddelim@@@"),
      )

      expect(adapter.analyze(prompt: "score this")).to eq("@@@startdelim@@@82@@@enddelim@@@")
    end

    it "raises when the key is missing" do
      bare = described_class.new(client: GeminiClient.new(api_key: nil))
      expect { bare.analyze(prompt: "x") }.to raise_error(Errors::ExternalServiceFailed, /GEMINI_API_KEY/)
    end

    it "raises on a non-success response" do
      stub_request(:post, /generativelanguage\.googleapis\.com/).to_return(status: 500, body: "boom")

      expect { adapter.analyze(prompt: "x") }.to raise_error(Errors::ExternalServiceFailed, /HTTP 500/)
    end
  end

  describe GeminiResumeRewriterAdapter do
    subject(:adapter) { described_class.new(client: GeminiClient.new(api_key: "k")) }

    it "honors the ResumeRewriterPort contract" do
      expect(adapter).to be_a(ResumeRewriterPort)
    end

    it "returns the rewritten text and sends resume + instructions" do
      stub_request(:post, /generativelanguage\.googleapis\.com/)
        .with(body: /make it concise.*my resume/m)
        .to_return(status: 200, body: gemini_body("NEW RESUME"))

      expect(adapter.rewrite(resume_text: "my resume", instructions: "make it concise")).to eq("NEW RESUME")
    end
  end
end
