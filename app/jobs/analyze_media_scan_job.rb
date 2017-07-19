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
    files_to_analyze_rel = MediaFile.where last_scan_id: media_scan_id, analyzed: false

    perform_analysis relation: files_to_analyze_rel, job_args: [ media_scan_id ], event: media_scan.last_scan_event, cause: media_scan, clear_errors: true do
      media_scan.finish_analysis!
    end
  end
end
