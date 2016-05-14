class Volume < Item
  before_save :normalize_isbn

  validates :original_release_date, presence: true
  validates :publisher, length: { maximum: 50, allow_blank: true }
  validates :version, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :isbn, uniqueness: { if: ->(b){ b.isbn.present? } }
  validate :isbn_valid

  validates :issn, absence: true
  validates :audio_languages, absence: true
  validates :subtitle_languages, absence: true

  def default_image_search_query
    items = [ super ]
    items << publisher if publisher
    items.join ' '
  end

  private

  def isbn_valid
    errors.add :isbn, :invalid_isbn if isbn.present? && !StdNum::ISBN.valid?(isbn.strip)
  end

  def normalize_isbn
    if isbn.present?
      isbn10 = isbn.gsub(/[^0-9X]+/, '').length == 10
      self.isbn = StdNum::ISBN.normalize(isbn).gsub(/[^0-9X]+/, '')
      self.isbn = StdNum::ISBN.convert_to_10 isbn if isbn10
    end
  end
end
