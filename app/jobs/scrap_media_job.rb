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

  def self.perform id
    scrap = MediaScrap.includes(:media_url).find id

    job_transaction cause: scrap, rescue_event: :fail_scraping!, clear_errors: true do
      Rails.application.with_current_event scrap.create_scrap_event do

        if scrap.contents.present?
          raise "Scrap #{api_id} was already scraped"
        elsif !%w(created retrying_scraping).include?(scrap.state)
          raise "Scrap #{scrap.api_id} cannot be scraped from state #{scrap.state}"
        end

        media_url = scrap.media_url

        start = Time.now
        Rails.logger.info "Scraping #{media_url.url} at #{Time.now} (#{scrap.api_id})"

        scrap.start_scraping!
        media_url.find_scraper.scrap scrap
        scrap.finish_scraping!

        duration = Time.now.to_f - start.to_f
        Rails.logger.info "Scraping #{scrap.api_id} completed in #{duration.round(3)}s"
      end
    end
  end
end
