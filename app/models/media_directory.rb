class MediaDirectory < MediaAbstractFile
  include SqlHelper

  has_many :files, class_name: 'MediaAbstractFile', foreign_key: :directory_id
  has_and_belongs_to_many :searches, class_name: 'MediaSearch', join_table: :media_directories_searches, foreign_key: :media_directory_id

  validates :path, format: { with: /\A(\/|(?:\/[^\/]+)+)\z/ }

  def self.delete_empty_directories relation:
    directory_ids_to_check_for_deletion = Set.new

    empty_directories = relation
      .joins('LEFT OUTER JOIN media_files AS child_files ON media_files.id = child_files.directory_id')
      .where('media_files.deleted = ?', false)
      .group('media_files.id')
      .having('SUM(CASE WHEN child_files.deleted = false THEN 1 ELSE 0 END) <= 0')
      .includes(:directory, :source)
      .to_a

    empty_directories.each do |directory|
      directory_ids_to_check_for_deletion << directory.directory_id unless directory.depth <= 0
      directory.deleted = true
      directory.save!
    end

    delete_empty_directories relation: MediaDirectory.where(id: directory_ids_to_check_for_deletion.to_a) if directory_ids_to_check_for_deletion.present?
  end

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
