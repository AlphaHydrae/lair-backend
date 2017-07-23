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
  event :restart_analysis, to: :processed, after: %i(reanalyze_files)

  belongs_to :scanner, class_name: 'MediaScanner'
  belongs_to :source, class_name: 'MediaSource', counter_cache: :scans_count
  has_many :file_changes, class_name: 'MediaScanChange', foreign_key: :scan_id
  has_many :job_errors, as: :cause, dependent: :destroy
  has_many :scanned_files, class_name: 'MediaFile', foreign_key: :last_scan_id

  strip_attributes
  validates :source, presence: true
  validates :scanner, presence: true
  validates :files_count, presence: { if: ->(scan){ %w(scanned processed).include? scan.state.to_s } }
  validate :changes_and_files_count_should_be_correct
  validate :changes_should_be_processed

  def last_scan_event
    ::Event.where(trackable: self).order('created_at DESC').first.tap do |event|
      raise "No scan event saved for media scan #{api_id}" unless event
    end
  end

  def analysis_progress
    if !analysis_started? || changed_files_count <= 0
      0
    else
      not_analyzed_count = scanned_files.where(analyzed: false).count
      not_analyzed_count <= 0 ? 1 : 1 - (not_analyzed_count.to_f / changed_files_count.to_f)
    end
  end

  def scanning_finished?
    state == 'scanned' || processing_started?
  end

  def processing_started?
    %w(processing processing_failed retrying_processing processed analyzed).include? state
  end

  def analysis_started?
    state == 'processed' || state == 'analyzed'
  end

  def changed_files_count
    added_files_count + modified_files_count + deleted_files_count
  end

  private

  def reanalyze_files
    scanned_files.update_all analyzed: false
  end

  def queue_process_job
    ProcessMediaScanJob.enqueue scan: self
  end

  def queue_analyze_job
    AnalyzeMediaScanJob.enqueue self
  end

  def create_scan_event
    ::Event.new(event_type: 'media:scan', user: source.user, trackable: self, trackable_api_id: api_id).tap &:save!
  end

  def changes_and_files_count_should_be_correct
    return unless state_changed? && state == 'scanned' && processed_changes_count == 0

    actual_added_files_count = count_changes_by_type :added
    if actual_added_files_count != added_files_count
      errors.add :added_files_count, :invalid_added_files_count
    end

    actual_deleted_files_count = count_changes_by_type :deleted
    if actual_deleted_files_count != deleted_files_count
      errors.add :deleted_files_count, :invalid_deleted_files_count
    end

    previous_files_count = source.files.where(deleted: false).count
    if previous_files_count + actual_added_files_count - actual_deleted_files_count != files_count
      errors.add :files_count, :invalid_files_count
    end
  end

  def count_changes_by_type type
    file_changes.where(change_type: type.to_s).count
  end

  def changes_should_be_processed
    return unless state_changed? && state == 'processed'
    errors.add :state, :unprocessed_changes if file_changes.where(processed: false).any?
  end

  def update_source_last_scan
    source.update_columns last_scan_id: id, scanned_at: created_at
  end
end
