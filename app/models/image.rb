class Image < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier

  has_many :items
  has_many :item_parts

  validates :url, presence: true, length: { maximum: 255 }
  validates :content_type, absence: { unless: :url }, length: { maximum: 50 }
  validates :width, absence: { unless: :url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :height, absence: { unless: :url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :size, absence: { unless: :url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :thumbnail_url, length: { maximum: 255 }
  validates :thumbnail_content_type, absence: { unless: :thumbnail_url }, length: { maximum: 50 }
  validates :thumbnail_width, absence: { unless: :thumbnail_url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :thumbnail_height, absence: { unless: :thumbnail_url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :thumbnail_size, absence: { unless: :thumbnail_url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }

  def fill_from_api_data data
    %i(url contentType width height size).each{ |attr| send "#{attr.to_s.underscore}=", data[attr] if data.key? attr }
    %i(url contentType width height size).each{ |attr| send "thumbnail_#{attr.to_s.underscore}=", data[:thumbnail][attr] if data[:thumbnail].key?(attr) } if data[:thumbnail].kind_of?(Hash) && data[:thumbnail].key?(:url)
    self
  end

  def to_builder
    Jbuilder.new do |json|
      json.id api_id unless new_record?
      json.url url
      json.contentType content_type if content_type
      json.width width if width
      json.height height if height
      json.size size if size
      json.thumbnail do
        json.url thumbnail_url || url
        json.contentType thumbnail_content_type || content_type if thumbnail_content_type || content_type
        json.width thumbnail_width || width if thumbnail_width || width
        json.height thumbnail_height || height if thumbnail_height || height
        json.size thumbnail_size || size if thumbnail_size || size
      end
    end
  end
end
