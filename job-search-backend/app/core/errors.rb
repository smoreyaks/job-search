# Shared core error types. Core and use cases raise these; one place (the
# controllers' base class) maps them to HTTP status. Adapters translate
# external failures into ExternalServiceFailed.
module Errors
  class Base < StandardError; end

  class NotFound < Base; end
  class ValidationFailed < Base; end
  class ExternalServiceFailed < Base; end
end
