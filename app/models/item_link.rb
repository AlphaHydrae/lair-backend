class ItemLink < ActiveRecord::Base

  belongs_to :item, touch: true
  belongs_to :language

  strip_attributes
  validates :url, presence: true, length: { maximum: 255 }, uniqueness: { scope: :item_id, allow_blank: true }
  validates :item, presence: true
end
