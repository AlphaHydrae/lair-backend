class MediaScrap < ActiveRecord::Base
  CONTENT_TYPES = %i(application/json application/xml)

  include SimpleStates
  include ResourceWithIdentifier
  include ResourceWithJobs
  include EncodingHelper

  before_create :set_identifier
  before_save :set_warnings_count
  before_save :clean_warnings
  before_save :clean_data
  after_commit :queue_scrap_job, on: :create

  auto_queueable_jobs :scrap, :expansion

  states :created, :scraping, :scraping_failed, :retrying_scraping, :scraped, :expanding, :expansion_failed, :retrying_expansion, :expanded
  event :start_scraping, to: :scraping
  event :fail_scraping, to: :scraping_failed
  event :retry_scraping, to: :retrying_scraping, after: :set_scrap_job_required
  event :finish_scraping, to: :scraped, after: :set_expansion_job_required
  event :start_expansion, to: :expanding, after: :clear_warnings
  event :fail_expansion, to: :expansion_failed
  event :retry_expansion, to: :retrying_expansion, after: :set_expansion_job_required
  event :finish_expansion, to: :expanded

  scope :without_contents, ->{ select column_names - %w(contents) }

  has_one :work
  belongs_to :media_url
  belongs_to :creator, class_name: 'User'
  has_many :events, as: :trackable
  has_many :job_errors, as: :cause, dependent: :destroy

  validates :provider, presence: true, inclusion: { in: MediaUrl::PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :contents, presence: { if: ->(scrap){ %i(scraped expanding expansion_failed expanded).include? scrap.state.to_s } }
  validates :content_type, presence: { if: :contents }, absence: { unless: :contents }, inclusion: { in: CONTENT_TYPES.collect(&:to_s), allow_blank: true }
  validates :media_url, presence: true, uniqueness: true

  def data
    if p = read_attribute(:data)
      p
    else
      write_attribute :data, {}
      read_attribute :data
    end
  end

  def warnings
    data['warnings'] ||= []
  end

  def clear_warnings
    data.delete 'warnings'
  end

  def last_scrap_event
    ::Event.where(trackable: self).order('created_at DESC').first.tap do |event|
      raise "No scrap event saved for scrap #{api_id}" unless event
    end
  end

  def create_scrap_event
    ::Event.new(event_type: 'media:scrap', user: creator, trackable: self, trackable_api_id: api_id).tap &:save!
  end

  private

  def queue_scrap_job
    ScrapMediaJob.enqueue self
  end

  def queue_expansion_job
    ExpandScrapJob.enqueue self
  end

  def set_warnings_count
    self.warnings_count = warnings.length
  end

  def clean_warnings
    data.delete 'warnings' if data['warnings'].blank?
  end

  def clean_data
    clean_utf8! data
    write_attribute :data, nil if read_attribute(:data).blank?
  end
end
