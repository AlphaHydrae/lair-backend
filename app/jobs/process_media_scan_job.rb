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

    job_transaction cause: scan, rescue_event: :fail_processing!, clear_errors: true do
      Rails.application.with_current_event scan.last_scan_event do

        unless %w(scanned retrying_processing).include? scan.state
          raise "Media scan #{scan.api_id} cannot be processed from state #{scan.state}"
        end

        scan.start_processing!

        changed_files_count = scan.changed_files_count
        if changed_files_count <= 0
          scan.finish_processing!
        else

          unprocessed_changes_rel = scan.file_changes.where processed: false
          remaining = unprocessed_changes_rel.count

          scan.update_column :processed_changes_count, changed_files_count - remaining

          offset = 0
          while offset < remaining

            first_id = unprocessed_changes_rel.order('media_scan_changes.id').offset(offset).first.id

            last_id = if offset + BATCH_SIZE <= remaining
              unprocessed_changes_rel.order('media_scan_changes.id').offset(offset + BATCH_SIZE - 1).first.id
            else
              unprocessed_changes_rel.order('media_scan_changes.id DESC').first.id
            end

            ProcessMediaScanChangesJob.enqueue scan: scan, first_id: first_id, last_id: last_id
            offset += BATCH_SIZE
          end
        end
      end
    end
  end
end
