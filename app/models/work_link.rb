class WorkLink < ActiveRecord::Base

  belongs_to :work, touch: true
  belongs_to :language

  strip_attributes
  validates :url, presence: true, length: { maximum: 255 }, uniqueness: { scope: :work_id, allow_blank: true }
  validates :work, presence: true
end
