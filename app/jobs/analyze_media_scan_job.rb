class AnalyzeMediaScanJob < AbstractAnalyzeMediaFilesJob
  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue scan, event = nil
    log_queueing "media scan #{scan.api_id}"
    enqueue_after_transaction self, scan.id, event.try(:id)
  end

  def self.lock_workers *args
    :media
  end

  def self.perform media_scan_id, event_id
    media_scan = MediaScan.includes(source: :user).find media_scan_id
    event = event_id ? ::Event.find(event_id) : media_scan.last_scan_event
    files_to_analyze_rel = MediaFile.where last_scan: media_scan, analyzed: false

    perform_analysis relation: files_to_analyze_rel, job_args: [ media_scan_id, event_id ], event: event, analysis_event_type: 'media:analysis:scan', analysis_user: media_scan.source.user, cause: media_scan, clear_errors: true do
      media_scan.finish_analysis!
    end
  end
end
