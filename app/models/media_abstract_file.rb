class MediaAbstractFile < ActiveRecord::Base
  include ResourceWithIdentifier

  self.table_name = 'media_files'

  before_create :set_identifier

  belongs_to :source, class_name: 'MediaSource', counter_cache: :files_count
  belongs_to :directory, class_name: 'MediaAbstractFile', counter_cache: :files_count

  strip_attributes
  # TODO: validate max depth
  validates :source, presence: true
  validates :path, presence: true, length: { maximum: 1000 }, uniqueness: { scope: :directory_id }
  validates :depth, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :path_must_be_absolute
  validate :parent_directory_must_not_be_self
  validate :parent_directory_must_not_be_a_parent
  validate :depth_must_fit_parent

  private

  def path_must_be_absolute
    errors.add :path, :must_be_absolute unless path.present? && path.match(/^\//)
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
    errors.add :depth, :invalid if depth.present? && directory.present? && depth != directory.depth + 1
  end
end
