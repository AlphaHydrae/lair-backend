class MediaAbstractFileSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.path record.path
    json.deleted record.deleted
    json.sourceId record.source.api_id
    json.analyzed record.analyzed

    basename = File.basename record.path
    json.basename basename

    dirname = File.dirname record.path
    json.dirname dirname if dirname != record.path
  end
end
