class MediaScanSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.startedAt record.started_at.iso8601(3)
  end
end
