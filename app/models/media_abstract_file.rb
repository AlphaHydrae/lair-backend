class MediaAbstractFile < ActiveRecord::Base
  include ResourceWithIdentifier

  self.table_name = 'media_files'

  before_create :set_identifier

  belongs_to :directory, class_name: 'MediaAbstractFile'
  belongs_to :source, class_name: 'MediaSource', counter_cache: :files_count

  strip_attributes
  validates :source, presence: true
  validates :path, presence: true, length: { maximum: 1000 }, uniqueness: { scope: :source_id }
  validates :depth, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validate :path_and_depth_must_be_consistent
  validate :parent_directory_must_not_be_self
  validate :parent_directory_must_not_be_a_parent
  validate :depth_must_fit_parent

  def directory?
    kind_of? MediaDirectory
  end

  def file?
    kind_of? MediaFile
  end

  def parent_directories &block
    MediaDirectory.where "media_files.id IN (#{parent_directories_sql(&block)})"
  end

  def parent_directory_files &block
    MediaFile.where "media_files.directory_id IN (#{parent_directories_sql(&block)})"
  end

  def parent_directories_sql

    rel = MediaDirectory
      .select('media_files.directory_id')
      .joins('INNER JOIN r ON media_files.id = r.current_id')
      .where('media_files.directory_id IS NOT NULL')

    rel = yield rel if block_given?

    sql = <<-SQL
      WITH RECURSIVE r(current_id) AS (
          VALUES(#{directory_id})
        UNION ALL
          #{rel.to_sql}
      ) SELECT current_id FROM r
    SQL

    strip_sql sql
  end

  private

  def path_and_depth_must_be_consistent
    return if path.blank? || depth.nil?
    errors.add :path, :invalid_path_depth if path.sub(/^\//, '').split(/\//).length != depth
  end

  def parent_directory_must_not_be_self
    errors.add :directory_id, :must_not_be_self if directory == self
  end

  def parent_directory_must_not_be_a_parent
    current_dir = directory

    while dir = current_dir.try(:directory)
      if dir == current_dir
        errors.add :directory_id, :must_not_be_a_parent
        break
      else
        current_dir = dir
      end
    end
  end

  def depth_must_fit_parent
    errors.add :depth, :invalid_directory_depth if depth.present? && directory.present? && depth != directory.depth + 1
  end
end
