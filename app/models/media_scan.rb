class MediaScan < ActiveRecord::Base
  include SimpleStates
  include ResourceWithIdentifier
  include ResourceWithProperties
  include ResourceWithJobs

  before_create :set_identifier

  auto_queueable_jobs :process, :analyze

  states :created, :canceled, :scanning, :scanned, :processing, :processing_failed, :retrying_processing, :processed, :analyzed
  event :start_scanning, to: :scanning
  event :cancel_scanning, to: :canceled
  event :finish_scanning, to: :scanned, after: %i(create_scan_event set_process_job_required)
  event :start_processing, to: :processing
  event :fail_processing, to: :processing_failed
  event :retry_processing, to: :retrying_processing, after: %i(set_process_job_required)
  event :finish_processing, to: :processed, after: %i(update_source_last_scan set_analyze_job_required)
  event :finish_analysis, to: :analyzed

  belongs_to :scanner, class_name: 'MediaScanner'
  belongs_to :source, class_name: 'MediaSource', counter_cache: :scans_count
  has_many :scanned_files, class_name: 'MediaScanFile', foreign_key: :scan_id
  has_many :job_errors, as: :cause, dependent: :destroy

  strip_attributes
  validates :source, presence: true
  validates :scanner, presence: true
  validates :files_count, presence: { if: ->(scan){ %w(scanned processed).include? scan.state.to_s } }
  validate :files_count_should_be_correct
  validate :scanned_files_should_be_processed

  def last_scan_event
    ::Event.where(trackable: self).order('created_at DESC').first.tap do |event|
      raise "No scan event saved for media scan #{api_id}" unless event
    end
  end

  def analysis_progress
    0
    # TODO analysis: compute analysis progress of media scan jobs
=begin
    total = changed_nfo_files_count + new_media_files_count
    current = analyzed_nfo_files_count + analyzed_media_files_count
    progress = current.to_f * 100.0 / total.to_f

    if progress >= 0 && progress <= 100
      progress.round 2
    elsif progress < 0
      0
    else
      100
    end
=end
  end

  def scanning_finished?
    state == 'scanned' || processing_started?
  end

  def processing_started?
    %w(processing processing_failed retrying_processing processed analyzed).include? state
  end

  def analysis_started?
    state == 'processed'
  end

  private

  def queue_process_job
    ProcessMediaScanJob.enqueue scan: self
  end

  def queue_analyze_job
    AnalyzeMediaScanJob.enqueue self
  end

  def create_scan_event
    ::Event.new(event_type: 'scan', user: source.user, trackable: self, trackable_api_id: api_id).tap &:save!
  end

  def files_count_should_be_correct
    return unless state_changed? && state == 'scanned' && processed_files_count == 0

    previous_files_count = source.files.where(deleted: false).count
    if previous_files_count + count_file_changes(:added) - count_file_changes(:deleted) != files_count
      errors.add :files_count, :invalid_files_count
    end
  end

  def count_file_changes type
    scanned_files.where(change_type: type.to_s).count
  end

  def scanned_files_should_be_processed
    return unless state_changed? && state == 'processed'
    errors.add :state, :unprocessed_files if scanned_files.where(processed: false).any?
  end

  def update_source_last_scan
    source.update_columns last_scan_id: id, scanned_at: created_at
  end
end
