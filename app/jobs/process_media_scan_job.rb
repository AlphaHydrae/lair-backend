require 'resque/plugins/workers/lock'

class ProcessMediaScanJob < ApplicationJob
  FILE_PROPERTIES = %i(url format languages subtitles)

  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue scan
    log_queueing "media scan #{scan.api_id}"
    enqueue_after_transaction self, scan.id
  end

  def self.lock_workers scan_id
    :media
  end

  def self.perform scan_id
    scan = MediaScan.includes(:source).find scan_id

    MediaScan.transaction do
      Rails.application.with_current_event scan.last_scan_event do

        scanned_at = Time.now

        scan.scanned_files.where(processed: false).find_in_batches batch_size: 250 do |scanned_files|

          directories_by_path = {}
          paths_to_check_for_deletion = Set.new

          scanned_files.each do |scanned_file|

            if scanned_file.deleted?
              if file = MediaFile.where(source_id: scan.source_id, path: scanned_file.path).first!
                paths_to_check_for_deletion << File.dirname(scanned_file.path)

                file.deleted = true
                file.mark_as_deleted if file.nfo?

                file.last_scan = scan
                file.scanned_at = scanned_at
                file.save!
              end
              next
            end

            directory_paths = []
            current_path = scanned_file.path

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

            directory = directories_by_path[File.dirname(scanned_file.path)]
            file = MediaFile.where(source_id: scan.source_id, path: scanned_file.path, directory_id: directory, depth: directory.depth + 1).first

            if file.blank?
              file = MediaFile.new
              file.source = scan.source
              file.directory = directory
              file.depth = directory.depth + 1
              file.path = scanned_file.path
            elsif file.deleted?
              file.media_url = nil
              file.mark_as_created
            elsif file.nfo?
              file.mark_as_changed
            end

            FILE_PROPERTIES.each do |key|
              if scanned_file.properties && value = scanned_file.properties[key.to_s]
                file.properties[key.to_s] = value
              else
                file.properties.delete key.to_s
              end
            end

            file.deleted = false

            file.last_scan = scan
            file.scanned_at = scanned_at
            file.bytesize = scanned_file.size
            file.file_created_at = scanned_file.file_created_at
            file.file_modified_at = scanned_file.file_modified_at
            file.save!
          end

          MediaDirectory.where(source_id: scan.source_id, path: directories_by_path.keys, deleted: true).update_all deleted: false

          paths_to_check_for_deletion -= directories_by_path.keys
          delete_directories scan, paths_to_check_for_deletion unless paths_to_check_for_deletion.empty?

          MediaScan.update_counters scan.id, processed_files_count: scanned_files.length
        end

        MediaScanFile.where(scan_id: scan.id).update_all processed: true

        scan.error_message = nil
        scan.error_backtrace = nil
        scan.finish_scan!

        scan.source.update_columns last_scan_id: scan.id, scanned_at: scan.created_at
      end
    end
  rescue => e
    scan.reload
    scan.error_message = e.message
    scan.error_backtrace = e.backtrace.join("\n")
    scan.fail_scan!
  end

  private

  def self.delete_directories scan, paths

    paths_to_check_for_deletion = Set.new

    directories = MediaDirectory
      .select('media_files.*, count(sub_media_files.id) AS deleted_files_count')
      .joins('INNER JOIN media_files AS sub_media_files ON media_files.id = sub_media_files.directory_id')
      .where('media_files.source_id = ? AND media_files.path IN (?) AND sub_media_files.deleted = ?', scan.source_id, paths, true)
      .group('media_files.id')
      .to_a

    directories.each do |directory|
      if directory.deleted_files_count == directory.files_count
        paths_to_check_for_deletion = File.dirname directory.path unless directory.depth <= 0
        directory.deleted = true
        directory.save!
      end
    end

    delete_directories scan, paths_to_check_for_deletion unless paths_to_check_for_deletion.empty?
  end
end
