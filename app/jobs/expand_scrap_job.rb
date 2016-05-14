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

  def self.perform id
    scrap = MediaScrap.includes(:media_url).find id

    unless %w(scraped expansion_failed expanded).include? scrap.state
      Rails.logger.warn "Scrap #{scrap.api_id} cannot be expanded from state #{scrap.state}"
      return
    end

    job_transaction cause: scrap, rescue_event: :fail_expansion!, clear_errors: true do
      Rails.application.with_current_event scrap.last_scrap_event do
        scrap.start_expansion!
        scrap.media_url.find_scraper.expand scrap
        scrap.finish_expansion!
      end
    end
  end
end
