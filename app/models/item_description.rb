class ItemDescription < ActiveRecord::Base
  include ResourceWithIdentifier
  before_create :set_identifier

  belongs_to :item, touch: true
  belongs_to :language

  strip_attributes
  validates :item, presence: true
  validates :language, presence: true
  validates :contents, presence: true, length: { maximum: 2500, allow_blank: true }
end
