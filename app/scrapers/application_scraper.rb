class ApplicationScraper
  def self.find_existing_work media_url
    Work.joins(:media_url).where('media_urls.id = ?', media_url.id).first
  end

  def self.find_existing_item work, media_url
    Item.joins(:media_url).where(work_id: work.id).where('media_urls.id = ?', media_url.id).first
  end
end
