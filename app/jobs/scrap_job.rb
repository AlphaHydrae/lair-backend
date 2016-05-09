require 'resque/plugins/workers/lock'

class ScrapJob < ApplicationJob
  extend Resque::Plugins::WaitingRoom
  extend Resque::Plugins::Workers::Lock

  can_be_performed times: 1, period: Rails.application.service_config(:scraping)[:interval]

  @queue = :low

  def self.enqueue scrap
    enqueue_after_transaction self, scrap.id
  end

  def self.lock_workers id
    :scraping
  end

  def self.perform id
    scrap = Scrap.includes(:media_url).find id
    Rails.application.with_current_event create_job_event(scrap, scrap.creator) do
      perform_scraping scrap if scrap.contents.blank?
      perform_expansion scrap if %w(scraped expansion_failed expanded).include? scrap.state.to_s
    end
  end

  def self.perform_scraping scrap
    MediaUrl.transaction do
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
  rescue => e
    scrap.reload
    scrap.error_message = e.message
    scrap.error_backtrace = e.backtrace.join "\n"
    scrap.fail_scraping!
  end

  def self.perform_expansion scrap
    MediaUrl.transaction do

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
