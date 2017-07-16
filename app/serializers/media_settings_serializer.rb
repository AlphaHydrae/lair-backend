class MediaSettingsSerializer < ApplicationSerializer
  def build json, options = {}
    json.userId record.user.api_id
    json.ignores record.ignores
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
