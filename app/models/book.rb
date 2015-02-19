class Book < ItemPart

  strip_attributes
  validates :publisher, length: { maximum: 50, allow_blank: true }
  validates :isbn, uniqueness: { if: ->(b){ b.isbn.present? } }
  validate :isbn_valid

  def default_image_search_query
    parts = [ super ]
    parts << publisher if publisher
    parts.join ' '
  end

  def to_builder
    builder = super
    builder.publisher publisher if publisher
    builder.isbn isbn if isbn
    builder
  end

  private

  def isbn_valid
    errors.add :isbn, :invalid_isbn if isbn.present? && !ISBN.valid?(isbn.strip)
  end
end
