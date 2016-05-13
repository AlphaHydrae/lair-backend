class Item < ActiveRecord::Base
  include ResourceWithIdentifier
  include ResourceWithImage
  include ResourceWithProperties
  include TrackedMutableResource

  before_create :set_identifier
  before_save :set_sortable_title
  before_destroy :cache_dependent_previous_versions
  after_save :update_work_years

  belongs_to :work
  belongs_to :title, class_name: 'WorkTitle'
  belongs_to :language
  belongs_to :custom_title_language, class_name: 'Language'
  has_many :ownerships, dependent: :destroy
  has_many :collection_items
  has_many :collections, through: :collection_items
  has_and_belongs_to_many :audio_languages, class_name: 'Language', join_table: :items_audio_languages, foreign_key: :video_id
  has_and_belongs_to_many :subtitle_languages, class_name: 'Language', join_table: :items_subtitle_languages, foreign_key: :video_id

  # TODO: make edition an enum

  strip_attributes
  validates :work, presence: true
  validates :title, presence: true
  validates :custom_title, length: { maximum: 255 }
  validates :custom_title_language, presence: { if: :custom_title }, absence: { unless: :custom_title }
  validates :original_release_date, presence: true
  validates :range_start, numericality: { only_integer: true, minimum: 1, maximum: 10000, allow_blank: true }
  validates :range_end, presence: { if: Proc.new{ |p| p.range_start.present? } }, numericality: { only_integer: true, minimum: 1, maximum: 10000, allow_blank: true }
  validates :language, presence: true
  validates :edition, length: { maximum: 25, allow_blank: true }
  validates :format, length: { maximum: 25, allow_blank: true }
  validates :length, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validate :title_belongs_to_parent
  validate :type_must_be_included_in_work_category
  validate :release_date_must_be_after_original_release_date

  def default_image_search_query
    parts = []

    if custom_title.present?
      parts << custom_title
    else
      parts << title.contents
      if range_start && range_end != range_start
        parts << "#{range_start}-#{range_end}"
      elsif range_start
        parts << range_start.to_s
      end
    end

    parts << edition if edition

    parts.join ' '
  end

  def effective_title
    if custom_title.present?
      custom_title
    else
      [ title.contents, range ].compact.join ' '
    end
  end

  private

  def range
    return nil unless range_start
    range_end != range_start ? "#{range_start}-#{range_end}" : range_start.to_s
  end

  def title_belongs_to_parent
    errors.add :title, :must_belong_to_parent if work.present? && title.present? && title.work != work
  end

  def type_must_be_included_in_work_category
    if work.present? && self.kind_of?(Volume) && !%w(book manga).include?(work.category.to_s)
      errors.add :type, :not_allowed_for_category
    elsif work.present? && self.kind_of?(Issue) && !%w(magazine).include?(work.category.to_s)
      errors.add :type, :not_allowed_for_category
    elsif work.present? && self.kind_of?(Video) && !%w(anime movie show).include?(work.category.to_s)
      errors.add :type, :not_allowed_for_category
    end
  end

  def release_date_must_be_after_original_release_date
    return unless release_date.present? && original_release_date.present?

    precisions = %w(y m d)
    index = [ precisions.index(release_date_precision), precisions.index(original_release_date_precision) ].min
    lowest_precision = precisions[index]

    normalized_release_date = date_to_precision release_date, lowest_precision
    normalized_original_release_date = date_to_precision original_release_date, lowest_precision

    errors.add :release_date, :invalid if normalized_release_date < normalized_original_release_date
  end

  def set_sortable_title
    sortable_range = "#{range_start.to_s.rjust(5, '0')}-#{range_end.to_s.rjust(5, '0')}"
    title_parts = [ title.contents, sortable_range ]
    title_parts << custom_title if custom_title.present?
    self.sortable_title = title_parts.join(' ').downcase
  end

  def date_to_precision date, precision
    case precision
    when 'y'
      Date.new date.year, 1, 1
    when 'm'
      Date.new date.year, date.month, 1
    when 'd'
      date
    end
  end

  def cache_dependent_previous_versions
    ownerships.each &:cache_previous_version
  end

  def update_work_years
    update_start_year = work.start_year.blank? || original_release_date.year < work.start_year
    update_end_year = work.end_year.blank? || original_release_date.year > work.end_year

    if update_start_year || update_end_year
      work.cache_previous_version
      work.start_year = original_release_date.year if update_start_year
      work.end_year = original_release_date.year if update_end_year
      work.updater = updater
      # TODO: set event cause
      work.save!
    end
  end
end
