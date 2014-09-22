class Ownership < ActiveRecord::Base

  belongs_to :item
  belongs_to :user

  strip_attributes
  validates :item, presence: true
  validates :user, presence: true
  validates :gotten_at, presence: true
end
