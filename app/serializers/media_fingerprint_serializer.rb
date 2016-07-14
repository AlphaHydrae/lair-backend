class MediaFingerprintSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id

    json.sourceId record.source.api_id
    json.mediaUrlId record.media_url.api_id

    json.totalSize record.total_bytesize
    json.totalFilesCount record.total_files_count
    json.contentSize record.content_bytesize
    json.contentFilesCount record.content_files_count

    json.createdAt record.created_at.iso8601(3) if record.created_at.present?
    json.updatedAt record.updated_at.iso8601(3) if record.updated_at.present?
  end
end
