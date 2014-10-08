require 'random'

class Item < ActiveRecord::Base
  before_create :set_key
  before_validation(on: :create){ complete_end_year }

  belongs_to :language
  belongs_to :original_title, class_name: 'ItemTitle'
  has_many :titles, class_name: 'ItemTitle'

  strip_attributes
  validates :category, presence: true, inclusion: { in: %w(anime book manga movie show), allow_blank: true }
  validates :number_of_parts, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :start_year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: -4000 }
  validates :end_year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: -4000 }
  validates :titles, presence: true
  validates :language, presence: true
  validate :year_range_valid

  def to_builder
    Jbuilder.new do |json|
      json.key key
      json.category category
      json.startYear start_year
      json.endYear end_year
      json.language language.iso_code
      json.numberOfParts number_of_parts if number_of_parts
      json.titles titles.all.to_a.sort_by(&:display_position).collect{ |t| t.to_builder.attributes! }
    end
  end

  private

  def set_key
    self.key = SecureRandom.random_alphanumeric 6
  end

  def complete_end_year
    self.end_year = start_year if end_year.nil?
  end

  def year_range_valid
    errors.add :end_year, :must_be_after_start_year if start_year.present? && end_year.present? && end_year < start_year
  end
end
