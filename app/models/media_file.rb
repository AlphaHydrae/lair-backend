class MediaFile < MediaAbstractFile
  include ResourceWithProperties

  belongs_to :last_scan, class_name: 'MediaScan'
  has_and_belongs_to_many :scans, class_name: 'MediaScan'

  strip_attributes
  validates :bytesize, presence: true, numericality: { only_integer: true, allow_blank: true }
  validates :file_created_at, presence: true
  validates :scanned_at, presence: true
end
