require 'resque/plugins/workers/lock'

class AnalyzeMediaFilesJob
  BATCH_SIZE = 250

  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue scan
    Resque.enqueue self, scan.id
  end

  def self.lock_workers id
    :media
  end

  def self.perform id
    analyze_files MediaScan.includes(:source).find(id)
  end

  def self.analyze_files scan
    MediaScan.transaction do
      source = scan.source

      MediaFile.where(source_id: source.id, extension: 'nfo', deleted: false, state: %w(created changed)).includes(:directory).find_each batch_size: BATCH_SIZE do |file|

        directory = file.directory

        directory_files_rel = MediaFile
          .where(source_id: source.id, deleted: false)
          .where('media_files.id != ? AND media_files.depth > ? AND media_files.path LIKE ?', file.id, directory.depth, "#{directory.path.gsub(/_/, '\\_').gsub(/\%/, '\\%')}/%")

        # FIXME: check parent directories
        if directory_files_rel.where(extension: 'nfo').any?
          file.mark_as_duplicated!
          next
        elsif file.url.blank?
          file.mark_as_invalid!
          mark_files directory_files_rel, :mark_as_unlinked
          next
        end

        scan_path = source.scan_paths.to_a.find do |sp|
          file.path.index("#{sp.path}/") == 0
        end

        media_url = MediaUrl.resolve file.url, source, scan_path.try(:category)
        if media_url.blank?
          file.mark_as_invalid!
          mark_files directory_files_rel, :mark_as_unlinked
          next
        end

        mark_files directory_files_rel, :mark_as_linked, media_url

        file.media_url = media_url
        file.mark_as_linked!
      end

      # TODO: apply existing NFOs to new files in existing directories
      # FIXME: unlink files when NFOs are deleted

      mark_files MediaFile.where(source_id: source.id, deleted: false, state: :created), :mark_as_unlinked

      # TODO: automatically clear previous scans' errors if successful
      scan.error_message = nil
      scan.error_backtrace = nil
      scan.finish_analysis!
    end
  rescue => e
    scan.reload
    scan.error_message = e.message
    scan.error_backtrace = e.backtrace.join "\n"
    scan.fail_analysis!
  end

  private

  def self.mark_files rel, mark_method, media_url = nil
    rel.find_each batch_size: BATCH_SIZE do |file|
      file.media_url = media_url
      file.send "#{mark_method}!"
    end
  end
end
