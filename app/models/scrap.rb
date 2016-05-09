class Scrap < ActiveRecord::Base
  CONTENT_TYPES = %i(application/json application/xml)

  include SimpleStates
  include ResourceWithIdentifier

  attr_accessor :job_to_queue

  before_create :set_identifier
  after_commit :queue_scrap_job, on: :create
  after_commit :auto_queue_job, on: :update

  states :created, :scraping, :scraping_canceled, :scraping_failed, :scraped, :expanding, :expansion_failed, :expanded
  event :start_scraping, to: :scraping
  event :cancel_scraping, to: :canceled
  event :fail_scraping, to: :scraping_failed
  event :retry_scraping, to: :created, after: :set_scrap_job_required
  event :finish_scraping, to: :scraped, after: :set_expand_job_required
  event :start_expansion, to: :expanding
  event :fail_expansion, to: :expansion_failed
  event :retry_expansion, to: :scraped, after: :set_expand_job_required
  event :finish_expansion, to: :expanded

  scope :without_contents, ->{ select column_names - %w(contents) }

  has_one :work
  belongs_to :media_url
  belongs_to :creator, class_name: 'User'
  has_many :events, as: :trackable

  validates :provider, presence: true, inclusion: { in: MediaUrl::PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :contents, presence: { if: ->(scrap){ %i(scraped expanding expansion_failed expanded).include? scrap.state.to_s } }
  validates :content_type, presence: { if: :contents }, absence: { unless: :contents }, inclusion: { in: CONTENT_TYPES.collect(&:to_s), allow_blank: true }
  validates :media_url, presence: true, uniqueness: true

  def scraping_event
    events.where(event_type: 'job').first
  end

  private

  def set_scrap_job_required
    self.job_to_queue = :scrap
  end

  def set_expand_job_required
    self.job_to_queue = :expand
  end

  def auto_queue_job
    if job_to_queue == :scrap
      queue_scrap_job
    elsif job_to_queue == :expand
      queue_expansion_job
    end

    self.job_to_queue = nil
  end

  def queue_scrap_job
    ScrapJob.enqueue self
  end

  def queue_expansion_job
    ExpandScrapJob.enqueue self
  end
end
