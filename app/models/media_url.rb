class MediaUrl < ActiveRecord::Base
  PROVIDERS = %i(anidb imdb)

  include ResourceWithIdentifier

  before_create :set_identifier
  after_create :queue_scraping

  has_one :scrap

  validates :provider, presence: true, inclusion: { in: PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :category, presence: true, inclusion: { in: Work::CATEGORIES, allow_blank: true }
  validates :provider_id, presence: true, length: { maximum: 100 }, uniqueness: { scope: :provider, case_sensitive: false }

  # IMDB URL example: http://www.imdb.com/title/tt0120815/
  # AniDB URL example: http://anidb.net/perl-bin/animedb.pl?show=anime&aid=4
  def self.resolve url, category = nil
    if match = url.match(/^https?:\/\/(?:www\.)?imdb\.com\/title\/([a-z0-9]+)/i)
      attrs = {
        provider: 'imdb',
        category: category || 'movie',
        provider_id: match[1]
      }

      MediaUrl.where(attrs).first_or_create!
    elsif match = url.match(/^https?:\/\/(?:www\.)?anidb\.net\/?.*\?.*aid=([a-z0-9]+).*/i)
      attrs = {
        provider: 'anidb',
        category: 'anime',
        provider_id: match[1]
      }

      MediaUrl.where(attrs).first_or_create!
    end
  end

  def queue_scraping
    return if scrap.present?

    scraper = find_scraper
    return unless scraper

    Scrap.new(media_url: self, provider: scraper.provider.to_s).save!
  end

  def find_scraper
    [ AnidbScraper, ImdbScraper ].find do |s|
      s.respond_to?(:scraps?) && s.scraps?(self)
    end
  end

  def url
    case provider.to_s
    when 'imdb'
      IMDB_URL_PATTERN % { provider_id: provider_id }
    when 'anidb'
      ANIDB_URL_PATTERN % { category: category, provider_id: provider_id }
    else
      raise "Unknown media URL provider #{provider}"
    end
  end

  private

  IMDB_URL_PATTERN = 'http://www.imdb.com/title/%{provider_id}'
  ANIDB_URL_PATTERN = 'http://anidb.net/perl-bin/animedb.pl?show=%{category}&aid=%{provider_id}'
end
