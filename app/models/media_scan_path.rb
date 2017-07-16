# TODO analysis: make media scan path a model
# TODO analysis: add ignores to scan paths
class MediaScanPath
  include Comparable
  include ActiveModel::Validations

  attr_accessor :id, :category, :path, :source

  validates :source, presence: true
  validates :category, presence: true, inclusion: { in: Work::CATEGORIES, allow_blank: true }
  validates :path, presence: true, length: { maximum: 255 }, format: { with: /\A(?:\/[^\/]+)+\z/ }
  validate :path_must_be_unique
  validate :path_must_not_be_relative_to_an_existing_path
  validate :path_must_not_include_an_existing_path

  def <=> other
    path <=> other.path
  end

  def generate_id
    self.id ||= SecureRandom.uuid
  end

  def to_data options = {}
    {
      'category' => category,
      'path' => path
    }
  end

  def to_h options = {}
    to_data(options).merge 'id' => id
  end

  def self.from_data source, id, data = {}
    new.tap do |scan_path|
      scan_path.source = source
      scan_path.id = id
      scan_path.category = data['category']
      scan_path.path = data['path']
    end
  end

  private

  def path_must_be_unique
    return if source.blank?
    errors.add :path, :taken if source.scan_paths.any?{ |sp| sp.path == path && sp.id != id }
  end

  def path_must_not_be_relative_to_an_existing_path
    return if source.blank? || path.blank?
    if scan_path = source.scan_paths.find{ |sp| sp.path == '/' || path.index("#{sp.path}/") == 0 }
      errors.add :path, :scan_path_already_included_in_existing_path, existing_path: scan_path.path
    end
  end

  def path_must_not_include_an_existing_path
    return if source.blank? || path.blank?
    if scan_path = source.scan_paths.find{ |sp| path == '/' || sp.path.index("#{path}/") == 0 }
      errors.add :path, :scan_path_includes_already_existing_paths, existing_path: scan_path.path
    end
  end
end
