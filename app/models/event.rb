class Event < ActiveRecord::Base
  TRACKED_MODELS = [ Company, Work, Item, Ownership, Person ]

  include ResourceWithIdentifier
  include Wisper::Publisher

  before_create :set_api_version
  before_create{ set_identifier{ SecureRandom.uuid } }
  after_create :broadcast_created

  belongs_to :user
  belongs_to :trackable, polymorphic: true
  belongs_to :cause, class_name: 'Event'

  validates :event_type, inclusion: { in: %w(create update delete job) }
  validates :event_subject, presence: { unless: :trackable }, length: { maximum: 50 }
  validates :trackable, presence: { unless: :event_subject }
  validates :previous_version, presence: { if: ->(e){ e.trackable.present? && %w(update delete).include?(e.event_type) } }
  validates :user, presence: { if: ->(e){ %w(create update delete).include?(e.event_type) } }

  def subject
    event_subject || trackable_type
  end

  private

  def set_api_version
    self.api_version = Rails.application.api_version
  end

  def broadcast_created
    broadcast :event_created, self
  end
end
