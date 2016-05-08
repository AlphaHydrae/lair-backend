class MediaAbstractFileSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.path record.path
    json.deleted record.deleted
    json.sourceId record.source.api_id
  end
end
