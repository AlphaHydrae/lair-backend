class MediaScan < ActiveRecord::Base
  include SimpleStates
  include ResourceWithIdentifier
  include ResourceWithProperties

  before_create :set_identifier

  self.initial_state = :started
  states :started, :canceled, :scanned, :failed, :processed
  event :cancel_scan, from: :started, to: :canceled
  event :finish_scan, from: :started, to: :scanned, after: :process_scan
  event :fail_scan, from: :scanned, to: :failed
  event :finish_scan_processing, from: :scanned, to: :processed

  belongs_to :scanner, class_name: 'MediaScanner'
  belongs_to :source, class_name: 'MediaSource', counter_cache: :scans_count
  has_many :scanned_files, class_name: 'MediaScanFile', foreign_key: :scan_id

  strip_attributes
  validates :source, presence: true
  validates :files_count, presence: { if: ->(scan){ %i(scanned processed).include? scan.state } }
  validate :files_count_should_be_correct
  validate :scanned_files_should_be_processed

  private

  def process_scan
    ProcessMediaScanJob.enqueue self
  end

  def files_count_should_be_correct
    return unless state_changed? && state == 'scanned'

    previous_files_count = source.files.count
    if previous_files_count + count_file_changes(:added) - count_file_changes(:deleted) != files_count
      errors.add :files_count, :invalid
    end
  end

  def count_file_changes type
    scanned_files.where(change_type: type.to_s).count
  end

  def scanned_files_should_be_processed
    return unless state_changed? && state == 'processed'

    if scanned_files.where(processed: false).any?
      errors.add :state, :invalid
    end
  end
end
