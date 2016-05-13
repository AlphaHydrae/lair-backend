require 'random'

# TODO: update part effective titles when title is modified
class Item < ActiveRecord::Base
  include ResourceWithIdentifier
  include ResourceWithImage
  include ResourceWithTags
  include TrackedMutableResource

  before_create{ set_identifier :api_id, 6 }
  before_validation(on: :create){ complete_end_year }

  belongs_to :language
  belongs_to :original_title, class_name: 'ItemTitle'
  has_many :titles, class_name: 'ItemTitle', dependent: :destroy, autosave: true
  has_many :links, class_name: 'ItemLink', dependent: :destroy, autosave: true
  has_many :descriptions, class_name: 'ItemDescription'
  has_many :relationships, class_name: 'ItemPerson', dependent: :destroy, autosave: true
  has_many :parts, class_name: 'ItemPart'

  strip_attributes
  validates :category, presence: true, inclusion: { in: %w(anime book manga movie show), allow_blank: true }
  validates :number_of_parts, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :start_year, numericality: { only_integer: true, greater_than_or_equal_to: -4000, allow_blank: true }
  validates :end_year, presence: { if: :start_year }, numericality: { only_integer: true, greater_than_or_equal_to: -4000, allow_blank: true }
  validates :titles, presence: true
  validates :language, presence: true
  validate :year_range_valid

  def default_image_search_query
    "#{titles[0].contents} #{category}"
  end

  private

  def complete_end_year
    self.end_year = start_year if end_year.nil?
  end

  def year_range_valid
    errors.add :end_year, :must_be_after_start_year if start_year.present? && end_year.present? && end_year < start_year
  end
end
