class MediaScrapSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.state record.state.to_s.camelize(:lower)
    json.scraper record.scraper.to_s

    json.mediaUrlId record.media_url.api_id
    json.mediaUrl serialize(record.media_url, (options[:media_url_options] || {}).merge(options.slice(:event)).merge(include_scrap: false)) if options.fetch(:include_media_url, options[:event])

    if options[:include_contents]
      json.contentType record.content_type if record.content_type.present?
      json.contents record.contents if record.contents.present?
    end

    json.warningsCount record.warnings_count
    if options[:include_warnings] && policy.admin?
      json.warnings record.warnings
    end

    if options[:include_errors] && policy.admin?
      json.errors serialize(record.job_errors.to_a)
    end

    %i(scraping_at scraping_failed_at retrying_scraping_at scraped_at expanding_at expansion_failed_at retrying_expansion_at expanded_at created_at updated_at).each do |ts|
      json.set! ts.to_s.camelize(:lower), record.send(ts).iso8601(3) if record.send(ts).present?
    end
  end
end
