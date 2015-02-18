class ItemDescription < ActiveRecord::Base
  include ResourceWithIdentifier
  before_create :set_identifier

  belongs_to :item
  belongs_to :language

  strip_attributes
  validates :item, presence: true
  validates :language, presence: true
  validates :contents, presence: true, length: { maximum: 2500, allow_blank: true }

  def to_builder
    Jbuilder.new do |json|
      json.id api_id
      json.text contents
      json.language language.tag
    end
  end
end
