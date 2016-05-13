class Company < ActiveRecord::Base
  include ResourceWithIdentifier
  include TrackedMutableResource
  before_create :set_identifier

  strip_attributes
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: true
end
