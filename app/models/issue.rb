class Issue < Item
  before_save :normalize_issn

  validates :publisher, length: { maximum: 50, allow_blank: true }
  validates :issn, uniqueness: { if: ->(b){ b.issn.present? } }
  validate :issn_valid

  validates :isbn, absence: true
  validates :audio_languages, absence: true
  validates :subtitle_languages, absence: true

  def default_image_search_query
    items = [ super ]
    items << publisher if publisher
    items.join ' '
  end

  private

  def issn_valid
    errors.add :issn, :invalid_issn if issn.present? && !StdNum::ISSN.valid?(issn.strip)
  end

  def normalize_issn
    if issn.present?
      self.issn = StdNum::ISSN.normalize(issn).gsub(/[^0-9X]+/, '')
    end
  end
end
