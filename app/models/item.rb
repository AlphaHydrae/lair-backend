class Item < ActiveRecord::Base

  has_many :titles, class_name: 'ItemTitle'
  belongs_to :original_title, class_name: 'ItemTitle'

  validates :year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: -4000 }
  validates :titles, presence: true
  validates :language, format: { with: /\A[a-z]{2}(?:\-[A-Z]{2})?\Z/ }

  def to_builder
    Jbuilder.new do |json|
      json.year year
      json.language language
      json.titles titles.sort_by(&:display_position).collect{ |t| t.to_builder.attributes! }
    end
  end
end
