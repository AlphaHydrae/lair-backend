class ApplicationScraper
  def self.scraps? media_url
    media_url.provider.to_s == provider.to_s
  end

  def self.find_or_build_work scrap
    work = find_existing_work scrap.media_url

    if work.present?
      work.cache_previous_version
      work.updater = scrap.creator
    else
      work = Work.new
      work.media_url = scrap.media_url
      work.creator = scrap.creator
    end

    work.media_scrap = scrap
    work.category = scrap.media_url.category

    work
  end

  def self.add_work_description scrap:, work:, description:, language:
    if description.present?

      if description.length > 5000
        description = description.truncate 5000
        scrap.warnings << "Truncated description because it is longer than 5000 characters"
      end

      if existing_description = work.descriptions.where(language: language).first
        existing_description.contents = description
      else
        work.descriptions.build work: work, contents: description, language: language
      end
    end
  end

  def self.find_existing_work media_url
    Work.joins(:media_url).where('media_urls.id = ?', media_url.id).first
  end

  def self.find_existing_item work, media_url
    Item.joins(:media_url).where(work_id: work.id).where('media_urls.id = ?', media_url.id).first
  end
end
