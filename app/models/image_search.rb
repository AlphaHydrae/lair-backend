class ImageSearch < ActiveRecord::Base
  include ResourceWithIdentifier
  attr_accessor :rate_limit

  before_create :set_identifier

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

  def to_builder
    Jbuilder.new do |json|
      json.id api_id
      json.query query
      json.engine engine
      json.results results
      json.searchedAt created_at.iso8601(3)
    end
  end
end
