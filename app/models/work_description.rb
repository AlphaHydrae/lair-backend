class WorkDescription < ActiveRecord::Base
  include ResourceWithIdentifier
  before_create :set_identifier

  belongs_to :work, touch: true
  belongs_to :language

  strip_attributes
  validates :work, presence: true
  validates :language, presence: true
  validates :contents, presence: true, length: { maximum: 5000, allow_blank: true }
end
