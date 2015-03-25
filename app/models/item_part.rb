# TODO: add effective title column to order by
class ItemPart < ActiveRecord::Base
  include ResourceWithIdentifier
  # TODO: set image of parent item automatically if not yet set
  include ResourceWithImage
  include ResourceWithTags
  include TrackedMutableResource

  before_create :set_identifier
  before_save :set_effective_title

  belongs_to :item
  belongs_to :title, class_name: 'ItemTitle'
  belongs_to :language
  belongs_to :custom_title_language, class_name: 'Language'
  has_many :ownerships

  strip_attributes
  validates :item, presence: true
  validates :title, presence: { unless: :custom_title }
  validates :custom_title, absence: { if: :title }, length: { maximum: 255 }
  validates :custom_title_language, presence: { if: :custom_title }, absence: { unless: :custom_title }
  validates :year, numericality: { only_integer: true, minimum: -4000, allow_blank: true }
  validates :original_year, presence: true, numericality: { only_integer: true, minimum: -4000, allow_blank: true }
  validates :range_start, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :range_end, presence: { if: Proc.new{ |p| p.range_start.present? } }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :language, presence: true
  validates :edition, length: { maximum: 25, allow_blank: true }
  validates :version, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :format, length: { maximum: 25, allow_blank: true }
  validates :length, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validate :title_belongs_to_parent
  validate :only_one_title

  def default_image_search_query
    parts = []

    if custom_title.present?
      parts << custom_title
    else
      parts << title.contents
      if range_start && range_end != range_start
        parts << "#{range_start}-#{range_end}"
      elsif range_start
        parts << range_start.to_s
      end
    end

    parts << edition if edition

    parts.join ' '
  end

  def to_builder options = {}
    Jbuilder.new do |json|
      json.id api_id
      json.itemId item.api_id
      json.item item.to_builder(options.slice(:image_from_search)) if options[:with_item]
      json.title do
        json.text effective_title
        json.language custom_title.present? ? custom_title_language.tag : title.language.tag
      end
      json.titleId title.api_id if title
      json.customTitle custom_title if custom_title
      json.customTitleLanguage custom_title_language.tag if custom_title_language
      json.year year if year
      json.originalYear original_year
      json.language language.tag
      json.start range_start if range_start
      json.end range_end if range_end
      json.edition edition if edition
      json.version version if version
      json.format format if format
      json.length length if length
      json.tags

      if options[:current_user] && options[:ownerships]
        json.ownedByMe options[:ownerships].any?{ |o| o.item_part_id == id && o.user_id == options[:current_user].id }
      end

      add_image_to_builder json, options
    end
  end

  private

  def range
    range_end != range_start ? "#{range_start}-#{range_end}" : range_start.to_s
  end

  def title_belongs_to_parent
    errors.add :title, :must_belong_to_parent if item.present? && title.present? && title.item != item
  end

  def only_one_title
    errors.add :custom_title, :cannot_be_combined_with_title if title.present? && custom_title.present?
  end

  def set_effective_title
    self.effective_title = if custom_title.present?
      custom_title
    else
      "#{title.contents} #{range}"
    end
  end
end
