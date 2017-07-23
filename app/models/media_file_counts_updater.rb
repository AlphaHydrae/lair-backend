class MediaFileCountsUpdater
  CHANGE_TYPES = %i(added deleted)
  COUNT_TYPES = %i(files_count nfo_files_count linked_files_count)

  def initialize
    @count_deltas_by_directory = {}
  end

  def track_file_change file:, change:
    raise "File must be a #{MediaFile.name}, got #{file.inspect}" unless file.kind_of? MediaFile
    raise "File must have a parent directory" unless file.directory

    delta = if change == :added
      1
    elsif change == :deleted
      -1
    else
      raise "Unsupported file count change type #{change.inspect} (must be one of #{CHANGE_TYPES.collect(&:to_s).join(', ')})"
    end

    update_count_delta file: file, type: :files_count, by: delta
    update_count_delta file: file, type: :nfo_files_count, by: delta
  end

  def track_file_linking linked:, file: nil, relation: nil
    raise "File must be a #{MediaFile.name}, got #{file.inspect}" unless file.nil? || file.kind_of?(MediaFile)
    raise "File must have a parent directory" unless file.nil? || file.directory

    if file
      delta = linked ? 1 : -1
      update_count_delta file: file, type: :linked_files_count, by: delta
    end

    if relation
      new_updates_rel = relation
        .select('media_files.directory_id, count(media_files.id) as link_or_unlinked_files_count')
        .where("media_files.media_url_id #{linked ? 'IS NULL' : 'IS NOT NULL'}")
        .group('media_files.directory_id')
        .includes(:directory)

      new_updates_rel.to_a.each do |file|
        delta = linked ? file.link_or_unlinked_files_count : -file.link_or_unlinked_files_count
        update_count_delta file: file, type: linked_files_count, by: delta
      end
    end
  end

  def apply
    @count_deltas_by_directory.each do |directory,counts_updates|
      directory.update_files_counts counts_updates
      directory.update_immediate_files_counts counts_updates
    end
  end

  private

  def update_files_counts directory:, count_deltas:
    statements = COUNT_TYPES.inject([]) do |memo,column|
      memo << update_files_count_statement(column: column, by: counts[column]) if counts.key?(column) && counts[column] != 0
      memo
    end

    with_parent_directories.update_all statements.join(', ') if statements.present?
  end

  def update_immediate_files_counts counts = {}
    statements = %i(nfo_files_count).inject [] do |memo,column|
      memo << update_files_count_statement(column: "immediate_#{column}", by: counts[column]) if counts.key?(column) && counts[column] != 0
      memo
    end

    MediaDirectory.where(id: id).update_all statements.join(', ') if statements.present?
  end

  def update_count_delta file:, type:, by:
    raise "Unsupported count type #{type}, must be one of #{COUNT_TYPES.collect(&:to_s).join(', ')}" unless COUNT_TYPES.include? type
    @count_deltas_by_directory[file.directory][type] += by
  end

  def update_files_count_statement column:, by:
    raise "Must not update #{column} by 0" if by == 0
    operator = by >= 0 ? '+' : '-'
    "#{column} = COALESCE(#{column}, 0) #{operator} #{by.abs}"
  end
end
