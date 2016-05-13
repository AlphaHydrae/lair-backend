class EventSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.apiVersion record.api_version
    json.type record.event_type
    json.createdAt record.created_at.iso8601(3)

    if %w(create update delete).include? record.event_type
      json.resource record.trackable_type.pluralize.underscore.gsub(/_/, '-')
    end

    json.previousVersion record.previous_version if %w(update delete).include? record.event_type

    if %w(create update).include?(record.event_type)

      trackable_type = record.trackable_type
      trackable_id = record.trackable_id

      next_event = Event.where trackable_type: trackable_type, trackable_id: trackable_id
      next_event = next_event.where('created_at > ?', record.created_at).limit(1).first

      if next_event.present?
        json.eventVersion next_event.previous_version
      elsif record.trackable.present?
        json.eventVersion serialize(record.trackable)
      end
    end
  end
end
