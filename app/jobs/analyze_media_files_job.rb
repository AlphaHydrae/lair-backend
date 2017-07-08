require 'resque/plugins/workers/lock'

class AnalyzeMediaFilesJob < ApplicationJob
  BATCH_SIZE = 250

  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue_scan scan
    log_queueing "media scan #{scan.api_id}"
    enqueue_after_transaction self, :scan, scan.id
  end

  def self.enqueue_file file
    log_queueing "media file #{file.api_id}"
    enqueue_after_transaction self, :file, file.id
  end

  def self.lock_workers *args
    :media
  end

  def self.perform type = nil, data = nil
    type = type.to_sym if type

    relation = nil
    job_cause = nil
    if type == :file
      relation = MediaFile.where id: data, analyzed: false
    elsif type == :scan
      relation = MediaFile.where last_scan_id: data, analyzed: false
    else
      relation = MediaFile.where analyzed: false
    end

    nfo_files_rel = relation.where(extension: 'nfo').limit(100)
    media_files_rel = relation.where('extension != ?', 'nfo').limit(100)

    if nfo_files.any?
      nfo_files.each{ |nfo_file| analyze_nfo_file nfo_file }
    end

    # TODO analysis: save media scan analyzed_at when analysis complete
=begin
    scan = MediaScan.includes(source: :user).find id

    job_transaction cause: scan, rescue_event: :fail_analysis!, clear_errors: true do
      Rails.application.with_current_event scan.last_scan_event do

        unless %w(processed retrying_analysis).include? scan.state
          raise "Media scan #{scan.api_id} cannot be analyzed from state #{scan.state}"
        end

        scan.start_analysis!

        source = scan.source

        changed_nfo_files_rel = MediaFile
          .where(source_id: source.id, extension: 'nfo')
          .where('(media_files.deleted = ? AND media_files.state = ?) OR (media_files.deleted = ? AND media_files.state IN (?))', true, 'deleted', false, %w(created changed))
          .includes(:directory)

        new_media_files_rel = MediaFile
          .where(source_id: source.id, deleted: false, state: 'created')
          .where('media_files.extension != ?', 'nfo')
          .includes(:directory)

        changed_nfo_files_count = changed_nfo_files_rel.count
        new_media_files_count = new_media_files_rel.count

        if changed_nfo_files_count + new_media_files_count >= 1

          updates = {}
          updates[:changed_nfo_files_count] = changed_nfo_files_count if scan.changed_nfo_files_count <= 0
          updates[:new_media_files_count] = new_media_files_count if scan.new_media_files_count <= 0
          scan.update_columns updates if updates.any?

          if changed_nfo_files_count >= 1
            # TODO: optimize NFO analysis by parallelizing by directory
            changed_nfo_files_rel.find_each do |nfo_file|
              AnalyzeChangedNfoFileJob.enqueue nfo_file: nfo_file, scan: scan
            end
          else
            analyze_remaining_media_files scan: scan
          end
        else
          scan.finish_analysis!
        end
      end
    end
=end
  end

  private

  def self.analyze_nfo_file nfo_file

    scan = MediaScan.includes(source: :user).find scan_id
    nfo_file = MediaFile.includes(:directory, :media_url).find nfo_file_id
    files_counts_updates = {}

    job_transaction cause: scan, rescue_event: :fail_analysis! do
      Rails.application.with_current_event scan.last_scan_event do

        affected_media_url = nfo_file.media_url

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

        affected_media_url ||= nfo_file.media_url
        UpdateMediaOwnershipsJob.enqueue media_url: affected_media_url, user: scan.source.user, event: scan.last_scan_event if affected_media_url.present?

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
      end
    end
  end

  def self.analyze_media_files relation

    scan = MediaScan.includes(source: :user).find scan_id
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
        affected_media_urls = Set.new

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
            affected_media_urls << nfo_files.first.media_url
          else
            # If no NFO file or multiple NFO files apply to this directory, or if
            # the NFO file that applies is not linked, mark all files in that directory
            # as unlinked.
            mark_files_as files: directory_files, state: :unlinked, files_counts_updates: files_counts_updates
          end
        end

        MediaDirectory.apply_tracked_files_counts updates: files_counts_updates

        affected_media_urls.each do |media_url|
          UpdateMediaOwnershipsJob.enqueue media_url: media_url, user: scan.source.user, event: scan.last_scan_event
        end

        analyzed_media_files_count = scan.analyzed_media_files_count + new_media_files_count
        if analyzed_media_files_count > scan.new_media_files_count
          raise "Unexpectedly analyzed #{analyzed_media_files_count} media files when there are only #{scan.new_media_files_count}"
        elsif analyzed_media_files_count == scan.new_media_files_count
          scan.analyzed_media_files_count = analyzed_media_files_count
          scan.finish_analysis!
        else
          MediaScan.update_counters scan.id, analyzed_media_files_count: new_media_files_count
        end
      end
    end
  end

  def self.media_files_for_directory directory:
    directory.child_files do |rel|
      rel.where 'media_files.type = ? AND media_files.deleted = ? AND media_files.extension != ?', MediaFile.name, false, 'nfo'
    end
  end

  def self.nfo_files_for_directory directory:
    directory_files_rel = directory.child_files do |rel|
      rel.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'
    end

    parent_directory_files_rel = directory.parent_directory_files.where 'media_files.deleted = ? AND media_files.extension = ?', false, 'nfo'

    directory_files_rel.to_a + parent_directory_files_rel.to_a
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
    relation.update_all state: state.to_s, media_url_id: media_url.try(:id)
  end

  def self.mark_files_as files:, state:, media_url: nil, files_counts_updates:
    relation = MediaFile.where id: files.collect(&:id)
    MediaDirectory.track_linked_files_counts updates: files_counts_updates, changed_relation: relation, linked: state.to_s == 'linked'
    relation.update_all state: state.to_s, media_url_id: media_url.try(:id)
  end
end
