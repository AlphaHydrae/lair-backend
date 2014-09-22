class ItemDescription < ActiveRecord::Base

  belongs_to :item

  strip_attributes
  validates :item, presence: true
  validates :language, presence: true
  validates :contents, presence: true, length: { maximum: 2500, allow_blank: true }
end
