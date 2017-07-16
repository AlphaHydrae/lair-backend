# TODO analysis: add ignores (not as property)
class MediaSource < ActiveRecord::Base
  include ResourceWithIdentifier
  include ResourceWithProperties

  before_create :set_identifier
  before_save :normalize_name
  before_save :serialize_scan_paths

  belongs_to :user
  belongs_to :last_scan, class_name: 'MediaScan'
  has_many :files, class_name: 'MediaFile', foreign_key: :source_id
  has_many :scans, class_name: 'MediaScan'

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false, scope: :user_id }
  validates :user, presence: true

  def data
    if d = read_attribute(:data)
      d
    else
      write_attribute :data, {}
      read_attribute :data
    end
  end

  def scan_paths
    unless @scan_paths
      @scan_paths = (self.data['scanPaths'] || {}).inject([]) do |memo,(id,data)|
        memo << MediaScanPath.from_data(self, id, data)
      end
    end

    @scan_paths
  end

  private

  def normalize_name
    self.normalized_name = name.to_s.downcase
  end

  def serialize_scan_paths
    if @scan_paths
      self.data['scanPaths'] = @scan_paths.inject({}) do |memo,sp|
        memo[sp.id] = sp.to_data
        memo
      end
    end

    true
  end
end
