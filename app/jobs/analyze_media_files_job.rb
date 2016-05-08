require 'resque/plugins/workers/lock'

class AnalyzeMediaFilesJob
  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue source
    Resque.enqueue self, source.id
  end

  def self.lock_workers id
    "media-#{id}"
  end

  def self.perform id
    source = MediaSource.find id

    MediaFile.transaction do
      MediaFile.where(extension: 'nfo', deleted: false, state: %w(unlinked changed)).includes(:directory).find_each batch_size: 250 do |file|

        directory = file.directory

        directory_files_rel = MediaFile
          .where(deleted: false)
          .where('media_files.id != ? AND media_files.depth > ? AND media_files.path LIKE ?', file.id, directory.depth, "#{directory.path.gsub(/_/, '\\_').gsub(/\%/, '\\%')}/%")

        if directory_files_rel.where(extension: 'nfo').any?
          file.mark_as_duplicated!
          next
        elsif file.url.blank?
          file.mark_as_invalid!
          next
        end

        scan_path = source.scan_paths.to_a.find do |sp|
          file.path.index("#{sp.path}/") == 0
        end

        media_url = MediaUrl.resolve file.url, source, scan_path.try(:category)
        if media_url.blank?
          file.mark_as_invalid!
          next
        end

        directory_files_rel.to_a.each do |associated_file|
          associated_file.media_url = media_url
          associated_file.mark_as_linked!
        end

        file.media_url = media_url
        file.mark_as_linked!
      end
    end
  end
end
