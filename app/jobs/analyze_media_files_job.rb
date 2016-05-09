require 'resque/plugins/workers/lock'

class AnalyzeMediaFilesJob < ApplicationJob
  BATCH_SIZE = 250

  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue scan
    enqueue_after_transaction self, scan.id
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

      # Handle deleted NFO files.
      MediaFile.where(source_id: source.id, extension: 'nfo', deleted: true, state: %w(deleted)).includes(:directory).find_each batch_size: BATCH_SIZE do |file|

        nfo_files = nfo_files_for_directory file.directory, file

        if nfo_files.length == 1 && nfo_files.first.state == 'duplicated'
          # If after deleting the NFO file, exactly one other NFO file applies
          # to this directory and it is marked as duplicated, process that NFO file
          # and other files in its directory.
          process_nfo_file nfo_files.first
        elsif nfo_files.blank?
          # If after deleting the NFO file, no other NFO file applies to this directory,
          # mark all its files as unlinked.
          mark_files directory_files_rel, :mark_as_unlinked
        end
      end

      # Handle new and modified NFO files.
      MediaFile.where(source_id: source.id, extension: 'nfo', deleted: false, state: %w(created changed)).includes(:directory).find_each batch_size: BATCH_SIZE do |file|

        nfo_files = nfo_files_for_directory file.directory, file

        if nfo_files.any?
          if file.state == 'changed'
            # If the NFO file was modified and other NFO files apply to this directory,
            # mark the NFO file as duplicated. Do not change the state of other files.
            file.mark_as_duplicated!
          else
            # If the NFO file is new and other NFO files apply to this directory,
            # mark all these NFO files as duplicated. Do not change the state of other
            # files.
            nfo_files.select{ |f| f.state != 'duplicated' }.each do |file|
              file.mark_as_duplicated!
            end
          end

          next
        end

        process_nfo_file file
      end

      # Handle new media files.
      MediaFile.where(source_id: source.id, deleted: false, state: 'created').where('media_files.extension != ?', 'nfo').includes(:directory).find_in_batches batch_size: BATCH_SIZE do |files|
        linked_nfos_by_directory_path = {}

        files.each do |file|

          nfo_file = linked_nfos_by_directory_path[file.directory.path]

          if nfo_file
            file.mark_as_linked!
            next
          elsif nfo_file == false
            file.mark_as_unlinked!
            next
          end

          nfo_files = nfo_files_for_directory(file.directory)

          if nfo_files.length == 1 && nfo_files.first.state == 'linked'
            # If exactly one NFO file applies to this directory and it is linked,
            # link the current file to the same media as the NFO file.
            file.media_url = nfo_files.first.media_url
            file.mark_as_linked!
            linked_nfos_by_directory_path[file.directory.path] = nfo_files.first
          else
            # If no NFO file applies to this directory,
            # mark the new file as unlinked.
            file.mark_as_unlinked!
            linked_nfos_by_directory_path[file.directory.path] = false
          end
        end

        processed_directories = nil
      end

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

  def self.media_files_for_directory directory
    directory.child_files do |rel|
      rel.where 'media_files.type = ? AND media_files.deleted = ? AND media_files.extension != ?', MediaFile.name, false, 'nfo'
    end
  end

  def self.nfo_files_for_directory directory, reference_nfo_file = nil

    directory_files_rel = directory.child_files do |rel|
      rel = rel.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'
      rel = rel.where 'media_files.id != ?', reference_nfo_file.id if reference_nfo_file.present?
      rel
    end

    parent_directory_files_rel = directory.parent_directory_files.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'

    directory_files_rel.to_a + parent_directory_files_rel.to_a
  end

  def self.process_nfo_file nfo_file

    source = nfo_file.source
    directory_files_rel = media_files_for_directory nfo_file.directory

    if nfo_file.url.blank?
      nfo_file.mark_as_invalid!
      mark_files directory_files_rel, :mark_as_unlinked
      return
    end

    scan_path = source.scan_paths.to_a.find do |sp|
      nfo_file.path.index("#{sp.path}/") == 0
    end

    media_url = MediaUrl.resolve nfo_file.url, source, scan_path.try(:category)
    if media_url.blank?
      nfo_file.mark_as_invalid!
      mark_files directory_files_rel, :mark_as_unlinked
      return
    end

    mark_files directory_files_rel, :mark_as_linked, media_url

    nfo_file.media_url = media_url
    nfo_file.mark_as_linked!
  end

  def self.mark_files rel, mark_method, media_url = nil

    n = 0

    rel.find_each batch_size: BATCH_SIZE do |file|
      file.media_url = media_url
      file.send "#{mark_method}!"
      n += 1
    end

    n
  end
end
