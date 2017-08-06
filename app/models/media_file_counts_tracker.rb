class MediaFileCountsTracker
  CHANGE_TYPES = %i(added modified deleted)
  COUNT_TYPES = %i(files_count nfo_files_count linked_files_count unanalyzed_files_count)
  IMMEDIATE_COUNT_TYPES = %i(immediate_nfo_files_count)
  ALL_COUNT_TYPES = COUNT_TYPES + IMMEDIATE_COUNT_TYPES

  def initialize
    reset_count_deltas
  end

  def track_change file:, change:
    raise "File must be a #{MediaFile.name}, got #{file.inspect}" unless file.kind_of? MediaFile
    raise "File must have a parent directory" unless file.directory

    delta = if %i(added modified).include? change
      1
    elsif change == :deleted
      -1
    else
      raise "Unsupported file count change type #{change.inspect} (must be one of #{CHANGE_TYPES.collect(&:to_s).join(', ')})"
    end

    if change != :modified
      update_count_delta file: file, type: :files_count, by: delta
      update_count_delta file: file, type: :nfo_files_count, by: delta if file.nfo?
      update_count_delta file: file, type: :immediate_nfo_files_count, by: delta if file.nfo?

      if change == :added
        update_count_delta file: file, type: :unanalyzed_files_count, by: delta
      elsif change == :deleted
        update_count_delta file: file, type: :linked_files_count, by: delta if file.media_url_id

        unanalyzed_delta = file.analyzed ? -1 : 1
        update_count_delta file: file, type: :unanalyzed_files_count, by: unanalyzed_delta if file.analyzed_changed?
      end
    else
      unanalyzed_delta = file.analyzed ? -1 : 1
      update_count_delta file: file, type: :unanalyzed_files_count, by: unanalyzed_delta if file.analyzed_changed?
    end
  end

  def track_linking linked:, file: nil, relation: nil
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
        update_count_delta file: file, type: :linked_files_count, by: delta
      end
    end
  end

  def track_analysis analyzed:, file: nil, relation: nil
    raise "File must be a #{MediaFile.name}, got #{file.inspect}" unless file.nil? || file.kind_of?(MediaFile)
    raise "File must have a parent directory" unless file.nil? || file.directory

    if file
      delta = analyzed ? -1 : 1
      update_count_delta file: file, type: :unanalyzed_files_count, by: delta
    end

    if relation
      new_updates_rel = relation
        .select('media_files.directory_id, count(media_files.id) as analyzed_or_unanalyzed_files_count')
        .where('media_files.analyzed', analyzed ? false : true)
        .group('media_files.directory_id')
        .includes(:directory)

      new_updates_rel.to_a.each do |file|
        delta = analyzed ? -file.analyzed_or_unanalyzed_files_count : file.analyzed_or_unanalyzed_files_count
        update_count_delta file: file, type: :unanalyzed_files_count, by: delta
      end
    end
  end

  def apply!
    @count_deltas_by_directory.each do |directory,count_deltas|
      update_files_counts directory: directory, count_deltas: count_deltas
      update_immediate_files_counts directory: directory, count_deltas: count_deltas
    end

    reset_count_deltas
  end

  private

  def update_files_counts directory:, count_deltas:
    statements = COUNT_TYPES.inject([]) do |memo,column|
      memo << update_files_count_statement(column: column, by: count_deltas[column]) if count_deltas.key?(column) && count_deltas[column] != 0
      memo
    end

    directory.with_parent_directories.update_all statements.join(', ') if statements.present?
  end

  def update_immediate_files_counts directory:, count_deltas:
    statements = IMMEDIATE_COUNT_TYPES.inject([]) do |memo,column|
      memo << update_files_count_statement(column: column, by: count_deltas[column]) if count_deltas.key?(column) && count_deltas[column] != 0
      memo
    end

    MediaDirectory.where(id: directory.id).update_all statements.join(', ') if statements.present?
  end

  def update_count_delta file:, type:, by:
    raise "Unsupported count type #{type}, must be one of #{ALL_COUNT_TYPES.collect(&:to_s).join(', ')}" unless ALL_COUNT_TYPES.include? type
    @count_deltas_by_directory[file.directory][type] += by
  end

  def update_files_count_statement column:, by:
    raise "Must not update #{column} by 0" if by == 0
    operator = by >= 0 ? '+' : '-'
    "#{column} = COALESCE(#{column}, 0) #{operator} #{by.abs}"
  end

  def reset_count_deltas
    @count_deltas_by_directory = Hash.new do |hash,key|
      hash[key] = ALL_COUNT_TYPES.inject({}){ |memo,type| memo[type] = 0; memo }
    end
  end
end
