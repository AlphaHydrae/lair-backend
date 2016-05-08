class MediaScan < ActiveRecord::Base
  include SimpleStates
  include ResourceWithIdentifier
  include ResourceWithProperties

  before_create :set_identifier

  self.initial_state = :started
  states :started, :canceled, :scanned, :failed, :processed, :analysis_failed, :analyzed
  event :cancel_scan, to: :canceled
  event :close_scan, to: :scanned, after: :process_scan
  event :fail_scan, to: :failed
  event :finish_scan, to: :processed
  event :fail_analysis, to: :analysis_failed
  event :finish_analysis, to: :analyzed

  belongs_to :scanner, class_name: 'MediaScanner'
  belongs_to :source, class_name: 'MediaSource', counter_cache: :scans_count
  has_many :scanned_files, class_name: 'MediaScanFile', foreign_key: :scan_id

  strip_attributes
  validates :source, presence: true
  validates :files_count, presence: { if: ->(scan){ %w(scanned processed analysis_failed analyzed).include? scan.state.to_s } }
  validate :files_count_should_be_correct
  validate :scanned_files_should_be_processed

  private

  def process_scan
    ProcessMediaScanJob.enqueue self
  end

  def files_count_should_be_correct
    return unless state_changed? && state == 'scanned'

    previous_files_count = source.files.where(deleted: false).count
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
