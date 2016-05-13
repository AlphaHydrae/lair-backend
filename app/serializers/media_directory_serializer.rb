class MediaDirectorySerializer < MediaAbstractFileSerializer
  def build json, options = {}
    super json, options
    json.type 'directory'
    json.filesCount record.files_count
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
