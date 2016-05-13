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

  def current_version
    trackable.to_builder.attributes!
  end

  def to_builder options = {}
    Jbuilder.new do |json|
      json.id api_id
      json.apiVersion api_version
      json.type event_type
      json.createdAt created_at.iso8601(3)

      if %w(create update delete).include? event_type
        json.resource trackable_type.pluralize.underscore.gsub(/_/, '-')
      end

      json.previousVersion previous_version if event_type == 'update'

      if %w(create update).include?(event_type) && trackable.present?
        next_event = trackable.events.where('created_at > ?', created_at).limit(1).first
        if next_event.present?
          json.eventVersion next_event.previous_version
        else
          json.eventVersion trackable.to_builder.attributes!
        end
      end
    end
  end

  private

  def set_api_version
    self.api_version = Rails.application.api_version
  end
end
