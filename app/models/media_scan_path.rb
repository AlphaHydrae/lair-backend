class MediaScanPath
  include Comparable
  include ActiveModel::Validations

  attr_accessor :id, :category, :path, :source

  validates :category, presence: true, inclusion: { in: Work::CATEGORIES, allow_blank: true }
  validates :path, presence: true, length: { maximum: 255 }
  validate :path_must_be_unique

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
    errors.add :path, :taken if source.scan_paths.any?{ |sp| sp.path == path && sp.id != id }
  end
end
