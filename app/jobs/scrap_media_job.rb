require 'resque/plugins/workers/lock'

class ScrapMediaJob < ApplicationJob
  extend Resque::Plugins::WaitingRoom
  extend Resque::Plugins::Workers::Lock

  can_be_performed times: 1, period: Rails.application.service_config(:scraping)[:interval]

  @queue = :low

  def self.enqueue scrap
    log_queueing "scrap #{scrap.api_id}"
    enqueue_after_transaction self, scrap.id
  end

  def self.lock_workers *args
    :scraping
  end

  def self.perform id, options = {}
    scrap = MediaScrap.includes(:media_url).find id

    if scrap.contents.blank?
      perform_scraping scrap
    else
      Rails.logger.warn "Scrap #{api_id} was already scraped"
    end
  end

  private

  def self.perform_scraping scrap
    MediaUrl.transaction do
      Rails.application.with_current_event scrap.create_scrap_event do
        media_url = scrap.media_url

        start = Time.now
        Rails.logger.info "Scraping #{media_url.url} at #{Time.now} (#{scrap.api_id})"

        scrap.start_scraping!
        media_url.find_scraper.scrap scrap

        scrap.error_message = nil
        scrap.error_backtrace = nil
        scrap.finish_scraping!

        duration = Time.now.to_f - start.to_f
        Rails.logger.info "Scraping #{scrap.api_id} completed in #{duration.round(3)}s"
      end
    end
  rescue => e
    scrap.reload
    scrap.error_message = e.message
    scrap.error_backtrace = e.backtrace.join "\n"
    scrap.fail_scraping!
  end
end
