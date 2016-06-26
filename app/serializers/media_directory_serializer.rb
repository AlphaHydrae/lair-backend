class MediaDirectorySerializer < MediaAbstractFileSerializer
  def build json, options = {}
    super json, options

    json.type 'directory'
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)

    json.filesCount record.files_count
    json.nfoFilesCount record.nfo_files_count
    json.linkedFilesCount record.linked_files_count

    if options[:include_media_search]
      media_search = record.media_search
      json.mediaSearch serialize(media_search) if media_search
    end
  end
end
