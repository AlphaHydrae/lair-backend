class ImageSearch < ActiveRecord::Base
  include ResourceWithIdentifier
  attr_accessor :rate_limit
  # TODO: delete previous unattached image searches

  before_create :set_identifier
  after_create :set_imageable_last_search

  belongs_to :user
  belongs_to :imageable, polymorphic: true

  strip_attributes
  validates :query, presence: true, length: { maximum: 255 }
  validates :engine, presence: true, inclusion: { in: %w(bing), allow_blank: true }
  validates :results_count, presence: true, numericality: { only_integer: true, minimum: 0 }

  def results= results
    self.results_count = results.length if results
    super results
  end

  def results?
    results_count > 0
  end

  def to_builder
    Jbuilder.new do |json|
      json.id api_id # TODO: unused?
      json.query query
      json.engine engine
      json.results results
      json.searchedAt created_at.iso8601(3)
    end
  end

  private

  def set_imageable_last_search
    imageable.class.where(id: imageable.id).update_all last_image_search_id: id
  end
end
