require 'resque/plugins/workers/lock'

class ProcessMediaScanJob
  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue scan, n
    Resque.enqueue self, scan.id, n
  end

  def self.lock_workers *args
    name
  end

  def self.perform id, n
    scan = MediaScan.where(id: id).first!

    MediaScan.transaction do

      scanned_at = Time.now
      directories_by_path = {}

      unprocessed_files = scan.scanned_files.where(processed: false).limit(n).to_a

      unprocessed_files.each do |scanned_file|

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

      if unprocessed_files.present?

        MediaScanFile.where(id: unprocessed_files.collect(&:id)).update_all processed: true

        scan.processed_files_count += unprocessed_files.length
        scan.processed_at = Time.now
        scan.save!

        scan.source.last_scan = scan
        scan.source.scanned_at = scan.created_at
        scan.source.save!
      end
    end
  end
end
