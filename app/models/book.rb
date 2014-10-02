class Book < ItemPart

  strip_attributes
  validates :publisher, presence: true, length: { maximum: 255, allow_blank: true }
  validates :isbn, presence: true, uniqueness: true, format: { with: /\A\d{9}(?:\d{3})?[\dX]\Z/, allow_blank: true }
end
