class MediaScanFile < ActiveRecord::Base
  belongs_to :scan, class_name: 'MediaFile'

  strip_attributes
  validates :data, presence: true
  validates :path, presence: true, uniqueness: { scope: :scan_id }
  validates :processed, inclusion: { in: [ true, false ] }

  def size
    data['size']
  end

  def file_created_at
    data['fileCreatedAt'] || data['fileModifiedAt']
  end

  def file_modified_at
    data['fileModifiedAt']
  end
end
