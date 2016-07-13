class Ownership < ActiveRecord::Base
  include ResourceWithIdentifier
  include ResourceWithProperties
  include TrackedMutableResource

  before_create :set_identifier
  before_save :set_owned

  belongs_to :item
  belongs_to :user
  belongs_to :media_url
  has_many :collection_ownerships
  has_many :collections, through: :collection_ownerships
  has_and_belongs_to_many :media_files

  strip_attributes
  validates :item, presence: true
  validates :user, presence: true
  validates :gotten_at, presence: true
  validate :yielded_at_must_be_after_gotten_at

  # TODO: add sortable_title ("X 10" should be after "X 2")

  private

  def yielded_at_must_be_after_gotten_at
    errors.add :yielded_at, :too_old if yielded_at.present? && yielded_at < gotten_at
  end

  def set_owned
    self.owned = !yielded_at
    true
  end
end
