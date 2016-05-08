class ScrapSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.state record.state.to_s.camelize(:lower)

    json.scrapingAt record.scraping_at.iso8601(3) if record.scraping_at.present?
    json.canceledAt record.canceled_at.iso8601(3) if record.canceled_at.present?
    json.scrapedAt record.scraped_at.iso8601(3) if record.scraped_at.present?
    json.failedAt record.failed_at.iso8601(3) if record.failed_at.present?

    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
