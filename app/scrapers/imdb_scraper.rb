class ImdbScraper < ApplicationScraper

  def self.scrap scrap
    scrap.contents = fetch_data scrap.media_url
    scrap.content_type = 'application/json'
    scrap.finish_scraping!
  end

  def self.scraps? media_url
    media_url.provider.to_s == 'imdb'
  end

  def self.provider
    :imdb
  end

  private

  OMDB_URL = 'http://www.omdbapi.com'

  def self.fetch_data media_url
    res = HTTParty.get(OMDB_URL, query: {
      'i' => media_url.provider_id,
      'plot' => 'full',
      'r' => 'json'
    })

    JSON.parse res.body
  end
end
