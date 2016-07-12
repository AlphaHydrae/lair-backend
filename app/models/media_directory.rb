class MediaDirectory < MediaAbstractFile
  include SqlHelper

  has_many :files, class_name: 'MediaAbstractFile', foreign_key: :directory_id
  has_and_belongs_to_many :searches, class_name: 'MediaSearch', join_table: :media_directories_searches, foreign_key: :media_directory_id

  def media_search
    searches.first
  end

  def update_files_counts counts = {}
    statements = %i(files_count nfo_files_count linked_files_count).inject [] do |memo,column|
      memo << update_files_count_statement(column: column, by: counts[column]) if counts.key?(column) && counts[column] != 0
      memo
    end

    with_parent_directories.update_all statements.join(', ') if statements.present?
  end

  def self.track_linked_files_counts updates:, linked:, changed_relation: nil, changed_file: nil

    if changed_file
      initialize_tracked_files_counts updates: updates, file: changed_file
      change = linked ? 1 : -1
      updates[changed_file.directory][:linked_files_count] += change
    end

    if changed_relation
      new_updates_rel = changed_relation
        .select('media_files.directory_id, media_files.state, count(media_files.id) as media_files_count')
        .where("media_files.state #{linked ? '!=' : '='} ?", 'linked')
        .group('media_files.directory_id')
        .includes(:directory)

      new_updates_rel.to_a.each do |file|
        initialize_tracked_files_counts updates: updates, file: file
        change = linked ? file.media_files_count : -file.media_files_count
        updates[file.directory][:linked_files_count] += change
      end
    end
  end

  def self.track_files_counts updates:, file:, change:

    initialize_tracked_files_counts updates: updates, file: file

    if change == :created
      updates[file.directory][:files_count] += 1
      updates[file.directory][:nfo_files_count] += 1 if file.nfo?
      updates[file.directory][:linked_files_count] += 1 if file.state.to_s == 'linked'
    elsif change == :deleted
      updates[file.directory][:files_count] -= 1
      updates[file.directory][:nfo_files_count] -= 1 if file.nfo?
      updates[file.directory][:linked_files_count] -= 1 if file.state.to_s == 'linked'
    elsif change == :unlinked
      updates[file.directory][:linked_files_count] -= 1
    else
      raise "Unsupported files count change type #{change.inspect}"
    end
  end

  def self.apply_tracked_files_counts updates:
    updates.each do |directory,counts_updates|
      directory.update_files_counts counts_updates
    end
  end

  def with_parent_directories
    MediaDirectory.where "media_files.id = #{id} OR media_files.id IN (#{parent_directories_sql})"
  end

  def child_files &block
    MediaAbstractFile.where "media_files.id IN (#{child_files_sql(&block)})"
  end

  def with_child_files &block
    MediaAbstractFile.where "media_files.id = #{id} OR media_files.id IN (#{child_files_sql(&block)})"
  end

  def child_files_sql

    rel = MediaAbstractFile
      .select('media_files.id')
      .joins('INNER JOIN r ON media_files.directory_id = r.current_id')
      .where('media_files.id != r.current_id')

    rel = yield rel if block_given?

    sql = <<-SQL
      WITH RECURSIVE r(current_id) AS (
          VALUES(#{id})
        UNION ALL
          #{rel.to_sql}
      ) SELECT current_id FROM r WHERE current_id != #{id}
    SQL

    strip_sql sql
  end

  private

  def self.initialize_tracked_files_counts updates:, file:
    updates[file.directory] ||= {
      files_count: 0,
      nfo_files_count: 0,
      linked_files_count: 0
    }
  end

  def update_files_count_statement column:, by: 0
    operator = by >= 0 ? '+' : '-'
    "#{column} = COALESCE(#{column}, 0) #{operator} #{by.abs}"
  end
end
