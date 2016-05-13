class CollectionOwnershipSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.collectionId record.collection.api_id
    json.ownershipId record.ownership.api_id
    json.createdAt record.created_at.iso8601(3)
  end
end
