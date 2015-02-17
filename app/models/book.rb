class Book < ItemPart

  strip_attributes
  validates :isbn, uniqueness: { if: ->(b){ b.isbn.present? } }
  validate :isbn_valid

  private

  def isbn_valid
    errors.add :isbn, :invalid_isbn if isbn.present? && !ISBN.valid?(isbn.strip)
  end
end
