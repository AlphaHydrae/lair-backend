class AnalyzeMediaScanJob < AbstractAnalyzeMediaFilesJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  # TODO: optional scan event
  # Rails.application.with_current_event scan.last_scan_event do
  def self.enqueue scan
    log_queueing "media scan #{scan.api_id}"
    enqueue_after_transaction self, scan.id
  end

  def self.lock_workers *args
    :media
  end

  def self.perform media_scan_id
    media_scan = MediaScan.find media_scan_id
    job_transaction cause: media_scan, clear_errors: true do
      perform_analysis relation: MediaFile.where(last_scan_id: media_scan_id, analyzed: false), subject_id: media_scan_id
    end
  end
end
