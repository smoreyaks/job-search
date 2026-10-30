module Domain
  # Plain-Ruby app config entity (the single config row): the localAppData
  # path, the Gemini response delimiter, and the Compare prompt instructions.
  AppConfig = Data.define(:id, :local_app_data, :delimiter, :compare_prompt) do
    def initialize(local_app_data:, delimiter:, id: nil, compare_prompt: nil)
      super
    end
  end
end
