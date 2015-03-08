class Ownership < ActiveRecord::Base
  include ResourceWithIdentifier
  include ResourceWithTags

  before_create :set_identifier

  belongs_to :item_part
  belongs_to :user

  strip_attributes
  validates :item_part, presence: true
  validates :user, presence: true
  validates :gotten_at, presence: true

  def to_builder options = {}
    Jbuilder.new do |json|
      json.id api_id
      json.partId item_part.api_id
      json.userId user.api_id
      json.tags tags
      json.gottenAt gotten_at.iso8601(3)

      json.part item_part.to_builder.attributes! if options[:with_part]
      json.user user.to_builder.attributes! if options[:with_user]
    end
  end
end
