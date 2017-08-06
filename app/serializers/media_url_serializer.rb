class MediaUrlSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id unless record.new_record?

    json.provider record.provider
    json.category record.category if record.category.present?
    json.providerId record.provider_id
    json.url record.url

    if record.work.present?
      json.workId record.work.api_id
      json.work serialize(record.work, (options[:work_options] || {}).merge(options.slice(:event)).merge(include_media_url: false)) if options.fetch(:include_work, options[:event])
    end

    if record.last_scrap.present?
      json.lastScrapId record.last_scrap.api_id
      json.lastScrap serialize(record.last_scrap, (options[:last_scrap_options] || {}).merge(options.slice(:event)).merge(include_media_url: false)) if options.fetch(:include_last_scrap, options[:event])
    end

    json.createdAt record.created_at.iso8601(3) if record.created_at.present?
    json.updatedAt record.updated_at.iso8601(3) if record.updated_at.present?
  end
end
