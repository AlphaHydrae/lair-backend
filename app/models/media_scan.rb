class MediaScan < ActiveRecord::Base
  include ResourceWithIdentifier
  include ResourceWithProperties

  before_create :set_identifier

  belongs_to :scanner, class_name: 'MediaScanner'
  belongs_to :source, class_name: 'MediaSource', counter_cache: :scans_count
  has_many :scanned_files, class_name: 'MediaScanFile', foreign_key: :scan_id

  strip_attributes
  validates :started_at, presence: true
  validates :source, presence: true
  validate :ended_at_must_be_after_started_at

  private

  def ended_at_must_be_after_started_at
    errors.add :ended_at, :invalid if started_at.present? && ended_at.present? && ended_at < started_at
  end
end
