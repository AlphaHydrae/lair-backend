class MediaUrlSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.provider record.provider
    json.category record.category
    json.providerId record.provider_id
    json.workId record.work.api_id if record.work.present?
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
