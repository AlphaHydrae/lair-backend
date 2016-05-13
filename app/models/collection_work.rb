class CollectionWork < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier

  belongs_to :collection, counter_cache: :linked_works_count
  belongs_to :work

  validates :collection, presence: true
  validates :work, presence: true
  validates :work_id, uniqueness: { scope: :collection_id }
end
