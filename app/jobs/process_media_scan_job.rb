require 'resque/plugins/workers/lock'

class ProcessMediaScanJob
  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue scan
    Resque.enqueue self, scan.id
  end

  def self.lock_workers *args
    name
  end

  def self.perform id
    process_files MediaScan.where(id: id).first!
  end

  def self.process_files scan
    MediaScan.transaction do

      scanned_at = Time.now
      directories_by_path = {}

      total = 0
      scan.scanned_files.where(processed: false).find_each batch_size: 250 do |scanned_file|
        total += 1

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
        file = MediaFile.where(path: scanned_file.path, directory_id: directory, depth: directory.depth + 1).first

        unless file
          file = MediaFile.new
          file.source = scan.source
          file.directory = directory
          file.depth = directory.depth + 1
          file.path = scanned_file.path
        end

        file.last_scan = scan
        file.scanned_at = scanned_at
        file.bytesize = scanned_file.size
        file.file_created_at = scanned_file.file_created_at
        file.file_modified_at = scanned_file.file_modified_at
        file.save!
      end

      MediaScanFile.where(scan_id: scan.id).update_all processed: true

      scan.processed_files_count += total
      scan.finish_scan_processing!

      scan.source.last_scan = scan
      scan.source.scanned_at = scan.created_at
      scan.source.save!
    end
  rescue => e
    scan.reload
    scan.backtrace = e.message + "\n" + e.backtrace.join("\n")
    scan.fail_scan!
  end
end
