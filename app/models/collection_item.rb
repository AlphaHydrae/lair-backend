class CollectionItem < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier

  belongs_to :collection, counter_cache: :linked_items_count
  belongs_to :item, class_name: 'Item'

  validates :collection, presence: true
  validates :item, presence: true
  validates :item_id, uniqueness: { scope: :collection_id }
end
