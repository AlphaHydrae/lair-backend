class ItemPart < ActiveRecord::Base
  include ResourceWithIdentifier
  before_create :set_identifier

  belongs_to :item
  belongs_to :title, class_name: 'ItemTitle'
  belongs_to :language

  strip_attributes
  validates :item, presence: true
  validates :title, presence: true
  validates :range_start, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :range_end, presence: { if: Proc.new{ |ip| ip.range_start.present? } }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :language, presence: true
  validates :edition, length: { maximum: 255, allow_blank: true }
  validates :version, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :format, length: { maximum: 255, allow_blank: true }
  validates :length, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :publisher, length: { maximum: 255, allow_blank: true }
  validate :title_belongs_to_parent
  # TODO: validate isbn

  def to_builder
    Jbuilder.new do |json|
      json.id api_id
      json.itemId item.api_id
      json.title title.to_builder
      json.language language.tag
      json.start range_start if range_start
      json.end range_end if range_end
      json.edition edition if edition
      json.version version if version
      json.format format if format
      json.length length if length
      json.publisher publisher if publisher
      json.isbn isbn if isbn
    end
  end

  private

  def title_belongs_to_parent
    errors.add :title, :must_belong_to_parent if item.present? && title.present? && title.item != item
  end
end
