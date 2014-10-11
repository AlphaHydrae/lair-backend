class ItemLink < ActiveRecord::Base

  belongs_to :item
  belongs_to :language

  strip_attributes
  validates :url, presence: true, uniqueness: { scope: :item_id, allow_blank: true }
  validates :item, presence: true

  def to_builder
    Jbuilder.new do |json|
      json.url url
    end
  end
end
