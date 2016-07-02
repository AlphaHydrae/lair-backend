require 'resque/plugins/workers/lock'

class AnalyzeRemainingMediaFilesJob < ApplicationJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue scan:, first_id:, last_id:
    log_queueing "media scan #{scan.api_id} new media files with IDs between #{first_id} and #{last_id}"
    enqueue_after_transaction self, scan.id, first_id, last_id
  end

  def self.lock_workers scan_id, first_id, last_id
    :media
  end

  def self.perform scan_id, first_id, last_id

    scan = MediaScan.find scan_id
    files_counts_updates = {}

    job_transaction cause: scan, rescue_event: :fail_analysis! do
      Rails.application.with_current_event scan.last_scan_event do

        new_media_files = MediaFile
          .where(source_id: scan.source_id, deleted: false, state: 'created')
          .where('media_files.extension != ?', 'nfo')
          .where('media_files.id >= ? AND media_files.id <= ?', first_id, last_id)
          .order('media_files.id')
          .includes(:directory)
          .to_a

        new_media_files_count = new_media_files.count

        while new_media_files.any?

          file = new_media_files.shift
          nfo_files = nfo_files_for_directory directory: file.directory

          directory_files = new_media_files.select{ |f| f.directory == file.directory }
          new_media_files -= directory_files

          if nfo_files.length == 1 && nfo_files.first.state == 'linked'
            # If exactly one NFO file applies to this directory and it is linked,
            # link the current file and all files in that directory to the same media
            # as the NFO file.
            mark_files_as files: directory_files, state: :linked, media_url: nfo_files.first.media_url, files_counts_updates: files_counts_updates
          else
            # If no NFO file or multiple NFO files apply to this directory, or if
            # the NFO file that applies is not linked, mark all files in that directory
            # as unlinked.
            mark_files_as files: directory_files, state: :unlinked, files_counts_updates: files_counts_updates
          end
        end

        MediaDirectory.apply_tracked_files_counts updates: files_counts_updates

        analyzed_media_files_count = scan.analyzed_media_files_count + new_media_files_count
        if analyzed_media_files_count > scan.new_media_files_count
          raise "Unexpectedly analyzed #{analyzed_media_files_count} media files when there are only #{scan.new_media_files_count}"
        elsif analyzed_media_files_count == scan.new_media_files_count
          scan.analyzed_media_files_count = analyzed_media_files_count
          scan.finish_analysis!
          Rails.logger.debug "TODO: update media ownerships after media files analysis (only for existing media URLs)"
        else
          MediaScan.update_counters scan.id, analyzed_media_files_count: new_media_files_count
        end
      end
    end
  end

  private

  def self.nfo_files_for_directory directory:

    directory_files_rel = directory.child_files do |rel|
      rel.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'
    end

    parent_directory_files_rel = directory.parent_directory_files.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'

    directory_files_rel.to_a + parent_directory_files_rel.to_a
  end

  def self.mark_files_as files:, state:, media_url: nil, files_counts_updates:
    relation = MediaFile.where id: files.collect(&:id)
    MediaDirectory.track_linked_files_counts updates: files_counts_updates, changed_relation: relation, linked: state.to_s == 'linked'
    relation.update_all state: state.to_s, media_url_id: media_url.try(:id)
  end
end
