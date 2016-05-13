class ImageSearchSerializer < ApplicationSerializer
  include ApiResourceHelper

  def build json, options = {}
    json.id record.api_id
    json.query record.query
    json.engine record.engine

    if record.imageable.present?
      json.resource model_to_resource_name(record.imageable.class)
      json.resourceId record.imageable.api_id
    end

    if options[:with_results]
      json.results record.results
    end

    json.searchedAt record.created_at.iso8601(3)
  end
end
