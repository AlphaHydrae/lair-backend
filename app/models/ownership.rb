class Ownership < ActiveRecord::Base
  include ResourceWithIdentifier
  before_create :set_identifier

  belongs_to :item
  belongs_to :user

  strip_attributes
  validates :item, presence: true
  validates :user, presence: true
  validates :gotten_at, presence: true

  def to_builder
    Jbuilder.new do |json|
      json.id api_id
      json.itemId item.api_id
      json.userId user.api_id
      json.gottenAt gotten_at.iso8601(3)
    end
  end
end
