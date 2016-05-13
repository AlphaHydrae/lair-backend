class ImageSearch < ActiveRecord::Base
  include ResourceWithIdentifier

  attr_accessor :rate_limit
  # TODO: delete previous unattached image searches

  before_create :set_identifier
  after_create :set_last_image_search
  after_create :clean_up_previous_searches

  belongs_to :user
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

  def set_last_image_search
    imageable_type.constantize.where(id: imageable_id).update_all last_image_search_id: self.id if imageable.present?
    true
  end

  def clean_up_previous_searches
    if imageable.present?
      ImageSearch.where(imageable: imageable).where('id != ?', self.id).delete_all
    else
      ImageSearch.where(user_id: self.user_id).where('imageable_id IS NULL AND id != ?', self.id).delete_all
    end
    true
  end
end
