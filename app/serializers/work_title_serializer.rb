class WorkTitleSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.text record.contents
    json.language record.language.tag
  end
end
