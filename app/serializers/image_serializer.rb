class ImageSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id unless record.new_record?
    json.state record.state unless record.new_record?
    json.url record.url
    json.contentType record.content_type if record.content_type
    json.width record.width if record.width
    json.height record.height if record.height
    json.size record.size if record.size
    json.createdAt record.created_at.iso8601(3) unless record.new_record?
    json.thumbnail do # TODO: fallback in view
      json.url record.thumbnail_url || record.url
      json.contentType record.thumbnail_content_type || record.content_type if record.thumbnail_content_type || record.content_type
      json.width record.thumbnail_width || record.width if record.thumbnail_width || record.width
      json.height record.thumbnail_height || record.height if record.thumbnail_height || record.height
      json.size record.thumbnail_size || record.size if record.thumbnail_size || record.size
    end
  end
end
