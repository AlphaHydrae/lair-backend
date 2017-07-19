# TODO analysis: add properties to events
# TODO. rename create/update/delete events to record:create/update/delete
class Event < ActiveRecord::Base
  EVENT_TYPES = %i(create update delete scan scrap)
  TRACKED_MODELS = [ Company, Work, Item, Ownership, Person ]

  include ResourceWithIdentifier
  include Wisper::Publisher

  before_create :set_api_version
  before_create{ set_identifier{ SecureRandom.uuid } }
  before_create :auto_set_cause
  after_create :broadcast_created

  belongs_to :user
  belongs_to :trackable, polymorphic: true
  belongs_to :cause, class_name: 'Event', counter_cache: :side_effects_count
  has_many :side_effects, class_name: 'Event', foreign_key: :cause_id

  validates :event_type, inclusion: { in: EVENT_TYPES.collect(&:to_s) }
  validates :event_subject, presence: { unless: :trackable }, length: { maximum: 50 }
  validates :trackable, presence: { unless: :event_subject }
  validates :previous_version, presence: { if: ->(e){ e.trackable.present? && %w(update delete).include?(e.event_type.to_s) } }

  def initialize *args
    super *args
    # TODO analysis: make sure this works
    @cause ||= Rails.application.current_event
  end

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

  def auto_set_cause
    self.cause ||= Rails.application.current_event
  end
end
