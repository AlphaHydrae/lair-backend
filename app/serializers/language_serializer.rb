class LanguageSerializer < ApplicationSerializer
  def build json, options = {}
    json.tag record.tag
    json.name record.name
    json.used record.used?
  end
end
