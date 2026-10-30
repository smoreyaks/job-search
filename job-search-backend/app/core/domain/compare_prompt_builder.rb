module Domain
  # Builds the Compare prompt: the instructions first, then the resume text,
  # then the job data, with explicit framing telling the AI to wrap each reply
  # field (score, then analysis) between the start/end delimiter markers so the
  # response can be parsed back apart reliably.
  class ComparePromptBuilder
    JOB_FIELDS = %i[
      company job_title location employment_type remote_type
      salary_range hourly_rate job_description
    ].freeze

    def build(instructions:, resume_text:, job_listing:, start_marker:, end_marker:)
      <<~PROMPT.strip
        #{instructions.to_s.strip}

        Format your reply as two fields in this exact order: first the numeric
        match score (0-100), then the written analysis. Wrap EACH field between
        #{start_marker} and #{end_marker}. Never use these markers anywhere else.

        === RESUME ===
        #{resume_text.to_s.strip}

        === JOB ===
        #{job_section(job_listing)}
      PROMPT
    end

    private

    def job_section(job_listing)
      data = job_listing.respond_to?(:to_h) ? job_listing.to_h : job_listing
      JOB_FIELDS.filter_map do |field|
        value = data[field]
        "#{field}: #{value}" unless value.nil?
      end.join("\n")
    end
  end
end
