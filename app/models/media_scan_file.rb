class MediaScanFile < ActiveRecord::Base
  CHANGE_TYPES = %i(added changed deleted)

  belongs_to :scan, class_name: 'MediaFile'

  strip_attributes
  validates :data, presence: true
  validates :path, presence: true, uniqueness: { scope: :scan_id }
  validates :processed, inclusion: { in: [ true, false ] }
  validates :change_type, presence: true, inclusion: { in: CHANGE_TYPES + CHANGE_TYPES.collect(&:to_s), allow_blank: true }

  %i(size file_created_at file_modified_at properties).each do |attr|
    define_method attr do
      data[attr.to_s.camelize(:lower)]
    end
  end

  def deleted?
    change_type.to_s == 'deleted'
  end
end
