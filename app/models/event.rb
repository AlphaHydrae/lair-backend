class Event < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_api_version
  before_create{ set_identifier{ SecureRandom.uuid } }

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
end
