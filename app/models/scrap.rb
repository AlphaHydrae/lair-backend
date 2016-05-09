class Scrap < ActiveRecord::Base
  CONTENT_TYPES = %i(application/json application/xml)

  include SimpleStates
  include ResourceWithIdentifier

  before_create :set_identifier
  after_commit :queue_job, on: :create

  states :created, :scraping, :scraping_canceled, :scraping_failed, :scraped, :expansion_failed, :expanded
  event :start_scraping, to: :scraping
  event :cancel_scraping, to: :canceled
  event :fail_scraping, to: :scraping_failed
  event :finish_scraping, to: :scraped
  event :fail_expansion, to: :expansion_failed
  event :finish_expansion, to: :expanded

  belongs_to :media_url
  belongs_to :creator, class_name: 'User'

  validates :provider, presence: true, inclusion: { in: MediaUrl::PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :contents, presence: { if: ->(scrap){ %i(scraped expansion_failed expanded).include? scrap.state.to_s } }
  validates :content_type, presence: { if: :contents }, absence: { unless: :contents }, inclusion: { in: CONTENT_TYPES.collect(&:to_s), allow_blank: true }
  validates :media_url, presence: true, uniqueness: true

  private

  def queue_job
    ScrapJob.enqueue self
  end
end
