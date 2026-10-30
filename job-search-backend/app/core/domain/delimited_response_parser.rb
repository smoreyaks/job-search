module Domain
  # Pulls each field out of the AI's reply. Every field is wrapped independently
  # between the same start/end marker pair, so this returns the inner contents of
  # each start...end segment in order (segment 0 = score, segment 1 = analysis).
  class DelimitedResponseParser
    def parse(text, start_marker:, end_marker:)
      pattern = /#{Regexp.escape(start_marker)}(.*?)#{Regexp.escape(end_marker)}/m
      text.to_s.scan(pattern).map { |capture| capture.first.strip }
    end
  end
end
