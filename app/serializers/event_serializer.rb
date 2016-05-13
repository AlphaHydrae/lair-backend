class EventSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.apiVersion record.api_version
    json.type record.event_type.to_s.camelize(:lower)

    json.cause !record.cause_id
    json.sideEffectsCount record.side_effects_count

    json.userId record.user.api_id if record.user.present?
    json.user serialize(record.user) if options[:with_user]

    if %w(create update delete job).include? record.event_type
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
        json.eventVersion serialize(record.trackable, { event: true })
      end
    elsif record.trackable.present?
      json.eventVersion serialize(record.trackable, { event: true })
    end

    json.createdAt record.created_at.iso8601(3)
  end
end
