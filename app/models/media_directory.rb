class MediaDirectory < MediaAbstractFile
  include SqlHelper

  has_many :files, class_name: 'MediaAbstractFile', foreign_key: :directory_id
  has_and_belongs_to_many :searches, class_name: 'MediaSearch', join_table: :media_directories_searches, foreign_key: :media_directory_id

  validates :path, format: { with: /\A(\/|(?:\/[^\/]+)+)\z/ }

  def media_search
    searches.first
  end

  def with_parent_directories &block
    MediaDirectory.where "media_files.id = #{id} OR media_files.id IN (#{parent_directories_sql(&block)})"
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
end
