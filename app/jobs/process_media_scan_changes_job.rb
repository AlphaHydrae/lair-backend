require 'resque/plugins/workers/lock'

class ProcessMediaScanChangesJob < ApplicationJob
  FILE_PROPERTIES = %i(url format languages subtitles)

  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue scan:, first_id:, last_id:
    log_queueing "media scan #{scan.api_id} changes with IDs between #{first_id} and #{last_id}"
    enqueue_after_transaction self, scan.id, scan.source_id, first_id, last_id
  end

  def self.lock_workers scan_id, source_id, first_id, last_id
    "media-#{source_id}"
  end

  def self.perform scan_id, source_id, first_id, last_id
    scan = MediaScan.includes(:source).find scan_id

    job_transaction cause: scan, rescue_event: :fail_processing! do
      Rails.application.with_current_event scan.last_scan_event do

        scanned_at = Time.now

        changes_rel = scan.file_changes.where('media_scan_changes.id >= ? AND media_scan_changes.id <= ?', first_id, last_id).order(:id)
        changes = changes_rel.to_a

        directories_by_path = {}
        files_counts_updates = {}
        paths_to_check_for_deletion = Set.new

        changes.each do |change|

          if change.deleted?
            if file = MediaFile.where(source_id: scan.source_id, path: change.path).includes(:directory).first!
              paths_to_check_for_deletion << File.dirname(change.path)

              MediaDirectory.track_files_counts updates: files_counts_updates, file: file, change: :deleted

              file.deleted = true
              file.analyzed = !file.nfo?
              file.last_scan = scan
              file.scanned_at = scanned_at
              file.save!
            end

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
            directories_by_path[path] = MediaDirectory.find_or_create_by!(source_id: scan.source_id, directory_id: parent_directory.try(:id), path: path, depth: i)
          end

          directory = directories_by_path[File.dirname(change.path)]
          file = MediaFile.where(source_id: scan.source_id, path: change.path, directory_id: directory, depth: directory.depth + 1).first

          if file.blank?
            file = MediaFile.new
            file.analyzed = false
            file.source = scan.source
            file.directory = directory
            file.depth = directory.depth + 1
            file.path = change.path
            MediaDirectory.track_files_counts updates: files_counts_updates, file: file, change: :created
          elsif file.deleted?
            file.media_url = nil
            file.analyzed = false
            MediaDirectory.track_files_counts updates: files_counts_updates, file: file, change: :created
          elsif file.nfo?
            file.analyzed = false
          end

          FILE_PROPERTIES.each do |key|
            if change.properties && value = change.properties[key.to_s]
              file.properties[key.to_s] = value
            else
              file.properties.delete key.to_s
            end
          end

          file.deleted = false

          file.last_scan = scan
          file.scanned_at = scanned_at
          file.bytesize = change.size
          file.file_created_at = change.file_created_at
          file.file_modified_at = change.file_modified_at
          file.save!
        end

        MediaDirectory.where(source_id: scan.source_id, path: directories_by_path.keys, deleted: true).update_all deleted: false

        paths_to_check_for_deletion -= directories_by_path.keys
        delete_directories scan, paths_to_check_for_deletion unless paths_to_check_for_deletion.empty?

        MediaDirectory.apply_tracked_files_counts updates: files_counts_updates

        changes_rel.update_all processed: true

        processed_changes_count = scan.processed_changes_count
        if processed_changes_count + changes.length > scan.changed_files_count
          raise "Unexpectedly processed #{processed_changes_count + changes.length} files when there are only #{scan.changed_files_count} files to process"
        elsif processed_changes_count + changes.length == scan.changed_files_count
          scan.processed_changes_count += changes.length
          scan.finish_processing!
        else
          MediaScan.update_counters scan.id, processed_changes_count: changes.length
        end
      end
    end
  end

  private

  def self.delete_directories scan, paths

    paths_to_check_for_deletion = Set.new

    directories = MediaDirectory
      .select('media_files.*, count(sub_media_files.id) AS not_deleted_files_count')
      .joins('INNER JOIN media_files AS sub_media_files ON media_files.id = sub_media_files.directory_id')
      .where('media_files.source_id = ? AND media_files.path IN (?) AND sub_media_files.deleted = ?', scan.source_id, paths, false)
      .group('media_files.id')
      .to_a

    directories.each do |directory|
      if directory.not_deleted_files_count <= 0
        paths_to_check_for_deletion << File.dirname(directory.path) unless directory.depth <= 0
        directory.deleted = true
        directory.save!
      end
    end

    delete_directories scan, paths_to_check_for_deletion unless paths_to_check_for_deletion.empty?
  end
end
