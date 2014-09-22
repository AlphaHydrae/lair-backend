class ItemTitle < ActiveRecord::Base

  belongs_to :item
  belongs_to :language

  strip_attributes
  validates :item, presence: true,
  validates :language, presence: true,
  validates :contents, presence: true, length: { maximum: 255, allow_blank: true }
  validates :display_position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, allow_blank: true }

  def to_builder
    Jbuilder.new do |title|
      title.text contents
    end
  end
end
