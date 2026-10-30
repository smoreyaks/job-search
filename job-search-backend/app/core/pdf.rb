# Small shared helper for validating that an upload is a PDF, by extension or
# by the %PDF magic-number header.
module Pdf
  def self.validate!(file_name, bytes)
    is_pdf = file_name.to_s.downcase.end_with?(".pdf") || bytes.to_s.start_with?("%PDF")
    raise Errors::ValidationFailed, "file must be a PDF" unless is_pdf
  end
end
