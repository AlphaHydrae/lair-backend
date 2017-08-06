class MediaFileSerializer < MediaAbstractFileSerializer
  def build json, options = {}
    super json, options

    json.type 'file'
    json.mediaType record.file_type.to_s.camelize(:lower)
    json.extension record.extension if record.extension.present?
    json.nfoError record.nfo_error if record.nfo?
    json.analyzed record.analyzed

    json.size record.bytesize
    json.fileCreatedAt record.file_created_at.iso8601(3) if record.file_created_at.present?
    json.fileModifiedAt record.file_modified_at.iso8601(3) if record.file_modified_at.present?
    json.properties record.properties

    json.sourceId record.source.api_id

    media_url = if options[:media_urls]
      options[:media_urls].find{ |url| url.id == record.media_url_id }
    else
      record.media_url
    end

    if media_url.present?
      json.mediaUrlId record.media_url.api_id
      json.mediaUrl serialize(record.media_url, options[:media_url_options] || {}) if options[:include_media_url]
    end

    json.scannedAt record.scanned_at.iso8601(3)
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
