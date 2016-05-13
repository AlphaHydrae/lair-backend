# TODO: decide what to do if title is marked for destruction and parts are attached to it
class ItemTitle < ActiveRecord::Base
  include ResourceWithIdentifier
  before_create :set_identifier

  belongs_to :item, touch: true
  belongs_to :language

  strip_attributes
  validates :item, presence: true
  validates :language, presence: true
  validates :contents, presence: true, length: { maximum: 150, allow_blank: true }
  validates :display_position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
end
