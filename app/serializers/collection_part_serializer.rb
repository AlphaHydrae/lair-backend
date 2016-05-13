class CollectionPartSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.collectionId record.collection.api_id
    json.partId record.part.api_id
    json.createdAt record.created_at.iso8601(3)
  end
end
