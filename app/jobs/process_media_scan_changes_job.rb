require 'resque/plugins/workers/lock'

class ProcessMediaScanChangesJob < ApplicationJob
  FILE_PROPERTIES = %i(url format languages subtitles)

  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue scan:, first_id:, last_id:
    log_queueing "media scan #{scan.api_id} changes with IDs between #{first_id} and #{last_id}"
    enqueue_after_transaction self, scan.id, scan.source_id, first_id, last_id
  end

  # TODO analysis: parallelize by locking directory updates and using first-level directories
  def self.lock_workers scan_id, source_id, first_id, last_id
    "media-#{source_id}"
  end

  def self.perform scan_id, source_id, first_id, last_id
    scan = MediaScan.includes(:source).find scan_id
    changes_rel = scan.file_changes.where('media_scan_changes.id >= ? AND media_scan_changes.id <= ?', first_id, last_id).order(:id)

    job_transaction cause: scan, rescue_event: :fail_processing! do
      Rails.application.with_current_event scan.last_scan_event do
        ProcessMediaScanChanges.new(scan: scan, changes_rel: changes_rel).perform
      end
    end
  end

  private

  class ProcessMediaScanChanges
    def initialize scan:, changes_rel:
      @scan = scan
      @changes_rel = changes_rel
      @counts_tracker = MediaFileCountsTracker.new
    end

    def perform
      scanned_at = Time.now

      changes = @changes_rel.to_a

      directories_by_path = {}
      directory_ids_to_check_for_deletion = Set.new

      deletions = changes.select &:deleted?
      deleted_files = MediaFile.where(source_id: @scan.source_id, path: deletions.collect(&:path)).includes(:directory).to_a

      changes.each do |change|

        if change.deleted?
          file = deleted_files.find{ |f| f.path == change.path }
          raise "Could not find deleted file #{change.path}" unless file

          directory_ids_to_check_for_deletion << file.directory_id

          file.deleted = true
          file.analyzed = !file.nfo?
          file.last_scan = @scan
          file.scanned_at = scanned_at

          # Must be done before saving the file to detect analyzed changes
          @counts_tracker.track_change file: file, change: :deleted

          file.save!

          next
        end

        directory_paths = []
        current_path = change.path

        n = 0
        loop do
          path = File.dirname current_path
          directory_paths.unshift path
          break if path == '/' || path == '.' || n >= 100
          current_path = path
          n += 1
        end

        directory_paths.each.with_index do |path,i|
          next if directories_by_path.key? path
          parent_directory = path == '/' ? nil : directories_by_path[File.dirname(path)]
          directories_by_path[path] = MediaDirectory.find_or_create_by!(source_id: @scan.source_id, directory_id: parent_directory.try(:id), path: path, depth: i)
        end

        directory = directories_by_path[File.dirname(change.path)]
        file = MediaFile.where(source_id: @scan.source_id, path: change.path, directory_id: directory, depth: directory.depth + 1).first

        if file.blank?
          file = MediaFile.new
          file.analyzed = false
          file.source = @scan.source
          file.directory = directory
          file.depth = directory.depth + 1
          file.path = change.path
          @counts_tracker.track_change file: file, change: :added
        elsif file.deleted?
          file.media_url = nil
          file.analyzed = !file.nfo?
          @counts_tracker.track_change file: file, change: :added
        elsif file.nfo?
          file.analyzed = false

          # Must be done before saving the file to detect analyzed changes
          @counts_tracker.track_change file: file, change: :modified
        end

        FILE_PROPERTIES.each do |key|
          if change.properties && value = change.properties[key.to_s]
            file.properties[key.to_s] = value
          else
            file.properties.delete key.to_s
          end
        end

        file.deleted = false

        file.last_scan = @scan
        file.scanned_at = scanned_at
        file.bytesize = change.size
        file.file_created_at = change.file_created_at
        file.file_modified_at = change.file_modified_at
        file.save!
      end

      MediaDirectory.where(id: directories_by_path.values.collect(&:id), deleted: true).update_all deleted: false, files_count: 0, nfo_files_count: 0, linked_files_count: 0, unanalyzed_files_count: 0, immediate_nfo_files_count: 0

      directory_ids_to_check_for_deletion -= directories_by_path.values.collect(&:id)
      MediaDirectory.delete_empty_directories MediaDirectory.where(id: directory_ids_to_check_for_deletion.to_a) if directory_ids_to_check_for_deletion.present?

      @counts_tracker.apply!
      @changes_rel.update_all processed: true

      processed_changes_count = @scan.processed_changes_count
      if processed_changes_count + changes.length > @scan.changed_files_count
        raise "Unexpectedly processed #{processed_changes_count + changes.length} files when there are only #{@scan.changed_files_count} files to process"
      elsif processed_changes_count + changes.length == @scan.changed_files_count
        @scan.processed_changes_count += changes.length
        @scan.finish_processing!
      else
        MediaScan.update_counters @scan.id, processed_changes_count: changes.length
      end
    end
  end
end
