class ItemPerson < ActiveRecord::Base
  # TODO: rename to ItemRelationship

  belongs_to :item, touch: true
  belongs_to :person

  strip_attributes
  validates :item, presence: true
  validates :person, presence: true
  # TODO: rename to relation
  validates :relationship, presence: true, inclusion: { in: %w(author), allow_blank: true }

  def to_builder
    Jbuilder.new do |json|
      json.relation relationship
      json.personId person.api_id
      json.person person.to_builder
    end
  end
end
