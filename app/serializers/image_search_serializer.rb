class ImageSearchSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id # TODO: unused?
    json.query record.query
    json.engine record.engine
    json.results record.results
    json.searchedAt record.created_at.iso8601(3)
  end
end
