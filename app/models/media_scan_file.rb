class MediaScanFile < ActiveRecord::Base
  CHANGE_TYPES = %i(added changed deleted)

  belongs_to :scan, class_name: 'MediaFile'

  strip_attributes
  validates :data, presence: true
  validates :path, presence: true, uniqueness: { scope: :scan_id }
  validates :processed, inclusion: { in: [ true, false ] }
  validates :change_type, presence: true, inclusion: { in: CHANGE_TYPES + CHANGE_TYPES.collect(&:to_s), allow_blank: true }

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
