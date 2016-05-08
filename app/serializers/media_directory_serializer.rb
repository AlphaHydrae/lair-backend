class MediaDirectorySerializer < MediaAbstractFileSerializer
  def build json, options = {}
    super json, options

    json.type 'directory'
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)

    counts = options.fetch(:directory_counts, {}).fetch(record.api_id, {})
    json.filesCount counts[:files_count] if options[:include_files_count]
    json.linkedFilesCount counts[:linked_files_count] if options[:include_linked_files_count]
  end
end
