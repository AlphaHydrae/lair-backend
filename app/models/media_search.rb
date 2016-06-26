class MediaSearch < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier

  belongs_to :user
  has_and_belongs_to_many :directories, class_name: 'MediaDirectory', join_table: :media_directories_searches

  validates :query, presence: true, length: { maximum: 255 }
  validates :provider, presence: true, inclusion: { in: MediaUrl::PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :selected_url, length: { maximum: 255 }
  validates :directories, presence: true

  def results= value
    super value
    self.results_count = value.try :length
  end
end
