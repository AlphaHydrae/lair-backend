class CollectionOwnership < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier

  belongs_to :collection, counter_cache: :linked_ownerships_count
  belongs_to :ownership

  validates :collection, presence: true
  validates :ownership, presence: true
  validates :ownership_id, uniqueness: { scope: :collection_id }
end
