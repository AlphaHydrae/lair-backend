class MediaFileSerializer < MediaAbstractFileSerializer
  def build json, options = {}
    super json, options
    json.type 'file'
    json.size record.bytesize
    json.fileCreatedAt record.file_created_at.iso8601(3) if record.file_created_at.present?
    json.fileModifiedAt record.file_modified_at.iso8601(3) if record.file_modified_at.present?
    json.scannedAt record.scanned_at.iso8601(3)
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
    json.properties record.properties
  end
end
