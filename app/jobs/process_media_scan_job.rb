require 'resque/plugins/workers/lock'

class ProcessMediaScanJob < ApplicationJob
  BATCH_SIZE = 250
  FILE_PROPERTIES = %i(url format languages subtitles)

  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue scan:
    log_queueing "media scan #{scan.api_id}"
    enqueue_after_transaction self, scan.id
  end

  def self.lock_workers scan_id
    :media
  end

  def self.perform scan_id
    scan = MediaScan.includes(:source).find scan_id

    job_transaction cause: scan, rescue_event: :fail_scan!, clear_errors: true do
      Rails.application.with_current_event scan.last_scan_event do
        files_count = scan.files_count
        if files_count <= 0
          scan.finish_scan!
        else
          offset = 0
          while offset < files_count
            ProcessMediaScanFilesJob.enqueue scan: scan, offset: offset, limit: BATCH_SIZE
            offset += BATCH_SIZE
          end
        end
      end
    end
  end
end
