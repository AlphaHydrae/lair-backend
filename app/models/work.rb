require 'random'

# TODO: update item effective titles when title is modified
class Work < ActiveRecord::Base
  CATEGORIES = %w(anime book magazine manga movie show)

  include ResourceWithIdentifier
  include ResourceWithImage
  include ResourceWithProperties
  include TrackedMutableResource

  before_create{ set_identifier size: 6 }
  before_validation(on: :create){ complete_end_year }
  before_destroy :cache_dependent_previous_versions
  after_commit :update_media_ownerships, on: :create

  belongs_to :language
  belongs_to :original_title, class_name: 'WorkTitle'
  belongs_to :media_url
  belongs_to :media_scrap
  has_many :titles, class_name: 'WorkTitle', dependent: :destroy, autosave: true
  has_many :links, class_name: 'WorkLink', dependent: :destroy, autosave: true
  has_many :descriptions, class_name: 'WorkDescription', dependent: :destroy, autosave: true
  has_many :person_relationships, class_name: 'WorkPerson', dependent: :destroy, autosave: true
  has_many :company_relationships, class_name: 'WorkCompany', dependent: :destroy, autosave: true
  has_many :items, class_name: 'Item', dependent: :destroy
  has_many :collection_works
  has_many :collections, through: :collection_works
  has_and_belongs_to_many :genres
  has_and_belongs_to_many :tags

  strip_attributes
  validates :category, presence: true, inclusion: { in: CATEGORIES, allow_blank: true }
  validates :number_of_items, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :start_year, numericality: { only_integer: true, greater_than_or_equal_to: -4000, allow_blank: true }
  validates :end_year, presence: { if: :start_year }, numericality: { only_integer: true, greater_than_or_equal_to: -4000, allow_blank: true }
  validates :titles, presence: true
  validates :language, presence: true
  validate :year_range_valid

  def default_image_search_query
    "#{titles[0].contents} #{category}"
  end

  def tree_new_or_changed?
    ([ self ] + titles + links + descriptions + person_relationships + company_relationships).any?{ |r| r.new_record? || r.changed? }
  end

  private

  def complete_end_year
    self.end_year = start_year if end_year.nil?
  end

  def year_range_valid
    errors.add :end_year, :must_be_after_start_year if start_year.present? && end_year.present? && end_year < start_year
  end

  def cache_dependent_previous_versions
    items.each &:cache_previous_version
  end

  def update_media_ownerships
    return unless media_url.present?
    UpdateMediaOwnershipsJob.enqueue media_url: media_url, user: creator, event: Rails.application.current_event
  end
end
