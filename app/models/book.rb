class Book < ItemPart

  strip_attributes
  validates :publisher, presence: true, length: { maximum: 255, allow_blank: true }
  validates :isbn10, uniqueness: true, format: { with: /\A\d{9}[\dX]\Z/, allow_blank: true }
  validates :isbn13, uniqueness: true, format: { with: /\A\d{12}[\dX]\Z/, allow_blank: true }
  validate :isbn_present

  private

  def isbn_present
    errors.add :base, :isbn_must_be_present if isbn10.blank? && isbn13.blank?
  end
end
