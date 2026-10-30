# Zeitwerk camelizes "jsearch_adapter" to "JsearchAdapter"; the class is named
# JSearchAdapter (capital S, matching the PRD), so teach the inflector that.
Rails.autoloaders.main.inflector.inflect(
  "jsearch_adapter" => "JSearchAdapter"
)
