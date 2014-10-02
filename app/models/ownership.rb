class Ownership < ActiveRecord::Base
  before_create :set_key

  belongs_to :item
  belongs_to :user

  strip_attributes
  validates :item, presence: true
  validates :user, presence: true
  validates :gotten_at, presence: true

  def to_builder
    Jbuilder.new do |json|
      json.key key
      json.itemKey item.key
      json.userKey user.key
      json.gottenAt gotten_at.iso8601(3)
    end
  end

  private

  def set_key
    self.key = SecureRandom.random_alphanumeric 12
  end
end
