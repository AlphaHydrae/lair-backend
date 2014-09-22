class ItemPart < ActiveRecord::Base

  belongs_to :item
  belongs_to :title, class: 'ItemTitle'
  belongs_to :language

  strip_attributes
  validates :item, presence: true
  validates :item_title, presence: true
  validates :range_start, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :range_end, presence: { if: Proc.new{ |ip| ip.range_start.present? } }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :language, presence: true
  validates :edition, length: { maximum: 255, allow_blank: true }
  validates :edition_number, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :format, length: { maximum: 255, allow_blank: true }
  validates :length, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validate :title_belongs_to_parent

  private

  def title_belongs_to_parent
    errors.add :title, :must_belong_to_parent if item.present? && title.present? && title.item != item
  end
end
