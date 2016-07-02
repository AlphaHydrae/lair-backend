require 'resque/plugins/workers/lock'

class AnalyzeChangedNfoFileJob < ApplicationJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue nfo_file:, scan:
    log_queueing "media scan #{scan.api_id} NFO file #{nfo_file.api_id}"
    enqueue_after_transaction self, scan.id, nfo_file.id
  end

  def self.lock_workers scan_id, nfo_file_id
    :media
  end

  def self.perform scan_id, nfo_file_id

    scan = MediaScan.includes(source: :user).find scan_id
    nfo_file = MediaFile.includes(:directory).find nfo_file_id
    files_counts_updates = {}

    job_transaction cause: scan, rescue_event: :fail_analysis! do
      Rails.application.with_current_event scan.last_scan_event do

        # Handle deleted NFO files.
        if nfo_file.deleted == true && nfo_file.state == 'deleted'
          other_nfo_files = other_nfo_files_for_directory directory: nfo_file.directory, not_nfo_file: nfo_file

          if other_nfo_files.length == 1 && other_nfo_files.first.state == 'duplicated'
            # If after deleting the NFO file, exactly one other NFO file applies
            # to this directory and it is marked as duplicated, process that NFO file
            # and other files in its directory.
            process_nfo_file nfo_file: other_nfo_files.first, scan: scan, files_counts_updates: files_counts_updates
          elsif other_nfo_files.blank?
            # If after deleting the NFO file, no other NFO file applies to this directory,
            # mark all its files as unlinked.
            directory_files_rel = media_files_for_directory directory: nfo_file.directory
            mark_files_as relation: directory_files_rel, state: :unlinked, scan: scan, files_counts_updates: files_counts_updates
          end

        # Handle new and modified NFO files.
        elsif nfo_file.deleted == false && %w(created changed).include?(nfo_file.state)

          other_nfo_files = other_nfo_files_for_directory directory: nfo_file.directory, not_nfo_file: nfo_file

          if other_nfo_files.any?
            if nfo_file.state == 'changed'
              # If the NFO file was modified and other NFO files apply to this directory,
              # mark the NFO file as duplicated. Do not change the state of other files.
              nfo_file.mark_as_duplicated!
            else
              # If the NFO file is new and other NFO files apply to this directory,
              # mark all these NFO files as duplicated. Do not change the state of other
              # files.
              MediaFile.where(id: other_nfo_files.collect(&:id)).where('media_files.state != ?', 'duplicated').update_all state: 'duplicated'
            end
          else
            process_nfo_file nfo_file: nfo_file, scan: scan, files_counts_updates: files_counts_updates
          end
        elsif nfo_file.state != 'duplicated'
          raise "Unexpected changed NFO file state: #{nfo_file.inspect}"
        end

        analyzed_nfo_files_count = scan.analyzed_nfo_files_count + 1
        if analyzed_nfo_files_count > scan.changed_nfo_files_count
          raise "Unexpectedly analyzed #{analyzed_nfo_files_count} NFO files when there are only #{scan.changed_nfo_files_count} that changed"
        else

          MediaScan.increment_counter :analyzed_nfo_files_count, scan.id

          if analyzed_nfo_files_count == scan.changed_nfo_files_count
            AnalyzeMediaFilesJob.analyze_remaining_media_files scan: scan
          end
        end

        MediaDirectory.apply_tracked_files_counts updates: files_counts_updates

        Rails.logger.debug "TODO: update media ownerships after media files analysis (only for existing media URLs)"
      end
    end
  end

  private

  def self.media_files_for_directory directory:
    directory.child_files do |rel|
      rel.where 'media_files.type = ? AND media_files.deleted = ? AND media_files.extension != ?', MediaFile.name, false, 'nfo'
    end
  end

  def self.other_nfo_files_for_directory directory:, not_nfo_file:

    directory_files_rel = directory.child_files do |rel|
      rel = rel.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'
      rel = rel.where 'media_files.id != ?', not_nfo_file.id
      rel
    end

    parent_directory_files_rel = directory.parent_directory_files.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'

    directory_files_rel.to_a + parent_directory_files_rel.to_a
  end

  def self.process_nfo_file nfo_file:, scan:, files_counts_updates:

    source = nfo_file.source
    directory_files_rel = media_files_for_directory directory: nfo_file.directory

    if nfo_file.url.blank?
      MediaDirectory.track_linked_files_counts updates: files_counts_updates, linked: false, changed_file: nfo_file if nfo_file.linked?
      nfo_file.mark_as_invalid!
      mark_files_as relation: directory_files_rel, state: :unlinked, scan: scan, files_counts_updates: files_counts_updates
      return
    end

    scan_path = source.scan_paths.to_a.find do |sp|
      nfo_file.path.index("#{sp.path}/") == 0
    end

    media_url = MediaUrl.resolve url: nfo_file.url, default_category: scan_path.try(:category), save: true, creator: source.user
    if media_url.blank?
      MediaDirectory.track_linked_files_counts updates: files_counts_updates, linked: false, changed_file: nfo_file if nfo_file.linked?
      nfo_file.mark_as_invalid!
      mark_files_as relation: directory_files_rel, state: :unlinked, scan: scan, files_counts_updates: files_counts_updates
      return
    end

    MediaDirectory.track_linked_files_counts updates: files_counts_updates, linked: true, changed_file: nfo_file unless nfo_file.linked?

    nfo_file.media_url = media_url
    nfo_file.mark_as_linked!

    mark_files_as relation: directory_files_rel, state: :linked, media_url: media_url, scan: scan, files_counts_updates: files_counts_updates
  end

  def self.mark_files_as relation:, state:, scan:, media_url: nil, files_counts_updates:

    MediaDirectory.track_linked_files_counts updates: files_counts_updates, changed_relation: relation, linked: state.to_s == 'linked'

    new_media_files_count = relation.where(state: 'created').count
    relation.update_all state: state.to_s, media_url_id: media_url.try(:id)

    if new_media_files_count >= 1
      scan.analyzed_media_files_count += new_media_files_count
      MediaScan.update_counters scan.id, analyzed_media_files_count: new_media_files_count
    end
  end
end
