class MediaSearchSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.query record.query
    json.provider record.provider

    json.results record.results if options[:include_results]
    json.resultsCount record.results_count

    json.selected record.selected if record.selected

    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
