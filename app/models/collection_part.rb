class CollectionPart < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier

  belongs_to :collection, counter_cache: :linked_parts_count
  belongs_to :part, class_name: 'ItemPart'

  validates :collection, presence: true
  validates :part, presence: true
  validates :part_id, uniqueness: { scope: :collection_id }
end
