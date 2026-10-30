require "net/http"
require "json"

# Thin client for Google's Gemini generateContent API, shared by the analyze
# and rewrite adapters. The API key comes from ENV (never committed); the model
# is overridable via GEMINI_MODEL. Raises ExternalServiceFailed on any failure.
class GeminiClient
  DEFAULT_MODEL = "gemini-3.5-flash-lite".freeze
  BASE = "https://generativelanguage.googleapis.com/v1beta/models".freeze

  def initialize(api_key: ENV["GEMINI_API_KEY"], model: ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL))
    @api_key = api_key
    @model = model
  end

  # Sends the prompt and returns the model's plain-text reply.
  def generate(prompt)
    if @api_key.to_s.strip.empty?
      raise Errors::ExternalServiceFailed, "Gemini API key not set (GEMINI_API_KEY)"
    end

    json = post({ contents: [{ parts: [{ text: prompt }] }] })
    json.dig("candidates", 0, "content", "parts", 0, "text").to_s
  end

  private

  def post(payload)
    uri = URI("#{BASE}/#{@model}:generateContent?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise Errors::ExternalServiceFailed, "Gemini request failed (HTTP #{response.code})"
    end

    JSON.parse(response.body)
  rescue Errors::ExternalServiceFailed
    raise
  rescue StandardError => e
    raise Errors::ExternalServiceFailed, "Gemini request error: #{e.message}"
  end
end
