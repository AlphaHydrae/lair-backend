class Video < Item
  validates :publisher, absence: true
  validates :version, absence: true
  validates :isbn, absence: true
  validates :issn, absence: true

  def special?
    special
  end
end
