# TODO: only save relevant data properties
class MediaScanFile < ActiveRecord::Base
  CHANGE_TYPES = %i(added modified deleted)

  belongs_to :scan, class_name: 'MediaFile'

  strip_attributes
  validates :data, presence: { unless: :deleted? }
  validates :path, presence: true, format: { with: /\A(?:\/[^\/]+)+\z/ }
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
