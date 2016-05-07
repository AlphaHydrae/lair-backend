class Scrap < ActiveRecord::Base
  CONTENT_TYPES = %i(application/json application/xml)

  include SimpleStates
  include ResourceWithIdentifier

  before_create :set_identifier
  after_create :queue_job

  states :created, :scraping, :canceled, :failed, :scraped
  event :start_scraping, to: :scraping
  event :cancel_scraping, to: :canceled
  event :fail_scraping, to: :failed
  event :finish_scraping, to: :scraped

  belongs_to :media_url

  validates :provider, presence: true, inclusion: { in: MediaUrl::PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :content_type, presence: { if: :contents }, absence: { unless: :contents }, inclusion: { in: CONTENT_TYPES.collect(&:to_s), allow_blank: true }
  validates :media_url, presence: true, uniqueness: true

  private

  def queue_job
    ScrapMediaUrlJob.enqueue self
  end
end
