class ApplicationScraper
  def self.find_existing_work media_url
    Work.joins(:media_url).where('media_urls.id = ?', media_url.id).first
  end
end
