class WorkLink < ActiveRecord::Base

  before_save :normalize_url

  belongs_to :work, touch: true
  belongs_to :language

  strip_attributes
  validates :url, presence: true, length: { maximum: 255 }, uniqueness: { scope: :work_id, case_sensitive: false, allow_blank: true }
  validates :work, presence: true

  private

  def normalize_url
    self.url = url.downcase unless url.nil?
  end
end
