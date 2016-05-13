class ImageSearch < ActiveRecord::Base
  include ResourceWithIdentifier
  include TrackedImmutableResource

  attr_accessor :rate_limit
  # TODO: delete previous unattached image searches

  before_create :set_identifier
  after_create :set_imageable_main_search

  belongs_to :creator, class_name: 'User'
  belongs_to :imageable, polymorphic: true

  strip_attributes
  validates :query, presence: true, length: { maximum: 255 }
  validates :engine, presence: true, inclusion: { in: %w(bingSearch googleCustomSearch), allow_blank: true }
  validates :results_count, presence: true, numericality: { only_integer: true, minimum: 0 }

  def results= results
    self.results_count = results.length if results
    super results
  end

  def results?
    results_count > 0
  end

  def check_rate_limit
    self.rate_limit = RateLimit.check_rate_limit engine
  end

  def check_rate_limit!
    self.rate_limit = RateLimit.check_rate_limit! engine
  end

  private

  def set_imageable_main_search
    imageable.class.where(id: imageable.id).update_all main_image_search_id: id if imageable.present?
  end
end
