require 'resque/plugins/workers/lock'

class ExpandScrapJob < ApplicationJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue scrap
    log_queueing "scrap #{scrap.api_id}"
    enqueue_after_transaction self, scrap.id
  end

  def self.lock_workers *args
    :scraping
  end

  def self.perform id, options = {}
    scrap = Scrap.includes(:media_url).find id
    Rails.application.with_current_event scrap.scraping_event do
      perform_expansion scrap if %w(scraped expansion_failed).include? scrap.state.to_s
    end
  end

  private

  def self.perform_expansion scrap
    MediaUrl.transaction do

      scrap.start_expansion!
      scrap.media_url.find_scraper.expand scrap

      scrap.error_message = nil
      scrap.error_backtrace = nil
      scrap.finish_expansion!
    end
  rescue => e
    scrap.reload
    scrap.error_message = e.message
    scrap.error_backtrace = e.backtrace.join "\n"
    scrap.fail_expansion!
  end
end
