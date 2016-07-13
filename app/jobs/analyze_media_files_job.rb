require 'resque/plugins/workers/lock'

class AnalyzeMediaFilesJob < ApplicationJob
  BATCH_SIZE = 250

  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue scan:
    log_queueing "media scan #{scan.api_id}"
    enqueue_after_transaction self, scan.id
  end

  def self.lock_workers scan_id
    :media
  end

  def self.perform id
    scan = MediaScan.includes(source: :user).find id

    job_transaction cause: scan, rescue_event: :fail_analysis!, clear_errors: true do
      Rails.application.with_current_event scan.last_scan_event do

        unless %w(processed retrying_analysis).include? scan.state
          raise "Media scan #{scan.api_id} cannot be analyzed from state #{scan.state}"
        end

        scan.start_analysis!

        source = scan.source

        changed_nfo_files_rel = MediaFile
          .where(source_id: source.id, extension: 'nfo')
          .where('(media_files.deleted = ? AND media_files.state = ?) OR (media_files.deleted = ? AND media_files.state IN (?))', true, 'deleted', false, %w(created changed))
          .includes(:directory)

        new_media_files_rel = MediaFile
          .where(source_id: source.id, deleted: false, state: 'created')
          .where('media_files.extension != ?', 'nfo')
          .includes(:directory)

        changed_nfo_files_count = changed_nfo_files_rel.count
        new_media_files_count = new_media_files_rel.count

        if changed_nfo_files_count + new_media_files_count >= 1

          updates = {}
          updates[:changed_nfo_files_count] = changed_nfo_files_count if scan.changed_nfo_files_count <= 0
          updates[:new_media_files_count] = new_media_files_count if scan.new_media_files_count <= 0
          scan.update_columns updates if updates.any?

          if changed_nfo_files_count >= 1
            # TODO: optimize NFO analysis by parallelizing by directory
            changed_nfo_files_rel.find_each do |nfo_file|
              AnalyzeChangedNfoFileJob.enqueue nfo_file: nfo_file, scan: scan
            end
          else
            analyze_remaining_media_files scan: scan
          end
        else
          scan.finish_analysis!
        end
      end
    end
  end

  def self.analyze_remaining_media_files scan:
    if scan.analyzed_media_files_count < scan.new_media_files_count
      remaining = scan.new_media_files_count - scan.analyzed_media_files_count

      new_media_files_rel = MediaFile
        .where(source_id: scan.source_id, deleted: false, state: 'created')
        .where('media_files.extension != ?', 'nfo')

      offset = 0
      while offset < remaining

        first_id = new_media_files_rel.order('media_files.id').offset(offset).first.id

        last_id = if offset + BATCH_SIZE <= remaining
          new_media_files_rel.order('media_files.id').offset(offset + BATCH_SIZE - 1).first.id
        else
          new_media_files_rel.order('media_files.id DESC').first.id
        end

        AnalyzeRemainingMediaFilesJob.enqueue scan: scan, first_id: first_id, last_id: last_id
        offset += AnalyzeMediaFilesJob::BATCH_SIZE
      end
    else
      scan.finish_analysis!
    end
  end
end
