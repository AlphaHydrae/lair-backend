class Language < ActiveRecord::Base

  strip_attributes
  validates :iso_code, presence: true, uniqueness: true, format: { with: /\A[a-z]{2}(?:\-[A-Z]{2})?\Z/, allow_blank: true }
end
