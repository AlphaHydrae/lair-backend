class ItemPerson < ActiveRecord::Base

  belongs_to :item
  belongs_to :person

  strip_attributes
  validates :item, presence: true
  validates :person, presence: true
  validates :relationship, presence: true, inclusion: { in: %w(author), allow_blank: true }
end
