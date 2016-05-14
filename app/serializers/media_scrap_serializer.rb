class MediaScrapSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.state record.state.to_s.camelize(:lower)

    json.mediaUrlId record.media_url.api_id
    json.mediaUrl serialize(record.media_url, (options[:media_url_options] || {}).merge(options.slice(:event)).merge(include_scrap: false)) if options.fetch(:include_media_url, options[:event])

    if options[:include_contents]
      json.contentType record.content_type if record.content_type.present?
      json.contents record.contents if record.contents.present?
    end

    json.scrapingAt record.scraping_at.iso8601(3) if record.scraping_at.present?
    json.scrapingFailedAt record.scraping_failed_at.iso8601(3) if record.scraping_failed_at.present?
    json.scrapedAt record.scraped_at.iso8601(3) if record.scraped_at.present?
    json.expansionFailedAt record.expansion_failed_at.iso8601(3) if record.expansion_failed_at.present?
    json.expandedAt record.expanded_at.iso8601(3) if record.expanded_at.present?

    json.warningsCount record.warnings_count
    if options[:include_warnings] && policy.admin?
      json.warnings record.warnings
    end

    if options[:include_errors] && policy.admin?
      json.errors serialize(record.job_errors.to_a)
    end

    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
