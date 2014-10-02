class ItemUrl < ActiveRecord::Base

  belongs_to :item
  belongs_to :language

  strip_attributes
  validates :contents, presence: true, uniqueness: { scope: :item_id, allow_blank: true }
  validates :item, presence: true
end
