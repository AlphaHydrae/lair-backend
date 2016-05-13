class CollectionWorkSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.collectionId record.collection.api_id
    json.workId record.work.api_id
    json.createdAt record.created_at.iso8601(3)
  end
end
