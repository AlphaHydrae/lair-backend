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

    if record.scrap.present?
      json.scrapId record.scrap.api_id
      json.scrap serialize(record.scrap, (options[:scrap_options] || {}).merge(options.slice(:event)).merge(include_media_url: false)) if options.fetch(:include_scrap, options[:event])
    end

    json.createdAt record.created_at.iso8601(3) if record.created_at.present?
    json.updatedAt record.updated_at.iso8601(3) if record.updated_at.present?
  end
end
