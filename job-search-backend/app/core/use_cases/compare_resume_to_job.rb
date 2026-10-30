module UseCases
  # Pure compute, no DB write. Reads the delimiter + prompt instructions from
  # config, builds the Compare prompt, sends it to the AI, and parses the raw
  # delimited reply into a score + analysis. Returns a Domain::ComparisonResult
  # (unpersisted; Save All is what writes it).
  class CompareResumeToJob
    def initialize(analyzer:, config:,
                   prompt_builder: Domain::ComparePromptBuilder.new,
                   parser: Domain::DelimitedResponseParser.new)
      @analyzer = analyzer
      @config = config
      @prompt_builder = prompt_builder
      @parser = parser
    end

    def call(resume_text:, job_listing:)
      raise Errors::ValidationFailed, "resume text is required" if resume_text.to_s.strip.empty?

      config = @config.current
      start_marker = config.delimiter
      end_marker = end_marker_for(start_marker)

      prompt = @prompt_builder.build(
        instructions: config.compare_prompt,
        resume_text: resume_text,
        job_listing: job_listing,
        start_marker: start_marker,
        end_marker: end_marker
      )

      raw = @analyzer.analyze(prompt: prompt)
      score_segment, analysis_segment = @parser.parse(raw, start_marker: start_marker, end_marker: end_marker)

      Domain::ComparisonResult.new(
        match_score: parse_score(score_segment),
        resume_suggestions: analysis_segment.to_s
      )
    end

    private

    # The config stores a single delimiter string as the START marker; the END
    # marker is derived from it ("@@@startdelim@@@" -> "@@@enddelim@@@"). See the
    # open-issue note: the PRD leaves whether Config holds one or two delimiter
    # fields unresolved; this is a pragmatic default to revisit.
    def end_marker_for(start_marker)
      start_marker.include?("start") ? start_marker.sub("start", "end") : "#{start_marker}/"
    end

    # Pull the first number out of the score segment; default to 0.0 on a
    # missing or unparseable score (handled gracefully, never raises).
    def parse_score(segment)
      number = segment.to_s[/-?\d+(?:\.\d+)?/]
      number ? number.to_f : 0.0
    end
  end
end
