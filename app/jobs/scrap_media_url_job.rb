class ScrapMediaUrlJob
  @queue = :low

  def self.enqueue scrap
    Resque.enqueue self, scrap.id
  end

  def self.perform id
    scrap = Scrap.find id
    media_url = scrap.media_url

    MediaUrl.transaction do
      scrap.start_scraping!
      media_url.find_scraper.scrap scrap
    end
  rescue => e
    scrap.reload
    scrap.error_message = e.message
    scrap.error_backtrace = e.backtrace.join "\n"
    scrap.fail_scraping!
  end
end
