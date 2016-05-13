class CollectionSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.name record.name
    json.displayName record.display_name
    json.userId record.user.api_id
    json.user serialize(record.user)
    json.public record.public_access
    json.featured record.featured

    if record.restrictions.present?
      json.restrictions do
        json.categories record.restrictions['categories'] if record.restrictions['categories'].present?
        json.owners record.restrictions['owners'] if record.restrictions['owners'].present?
      end
    else
      json.restrictions({})
    end

    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
