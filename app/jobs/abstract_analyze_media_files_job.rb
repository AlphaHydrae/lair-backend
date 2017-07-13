require 'resque/plugins/workers/lock'

class AbstractAnalyzeMediaFilesJob < ApplicationJob
  BATCH_SIZE = 100

  def self.perform_analysis relation:, subject_id:, &block
    relation = relation.includes :directory, :media_url, source: :user

    nfo_files_rel = relation.where extension: 'nfo'
    nfo_files_count = nfo_files_rel.count
    if nfo_files_count >= 1
      nfo_files = nfo_files_rel.limit(BATCH_SIZE).to_a
      Rails.logger.debug "Analyzing #{nfo_files.length} NFO files"
      nfo_files.each{ |f| analyze_nfo_file f }
    else
      Rails.logger.debug 'No more NFO files to analyze'
    end

    if nfo_files_count > BATCH_SIZE
      Rails.logger.debug "#{nfo_files_count - BATCH_SIZE} NFO files left to analyze"
      return enqueue_next subject_id
    end

    remaining_batch_size = BATCH_SIZE - nfo_files_count

    media_files_rel = relation.where 'extension != ?', 'nfo'
    media_files_count = media_files_rel.count
    if media_files_count <= 0
      Rails.logger.debug 'No more media files to analyze'
      return finish_analysis &block
    elsif remaining_batch_size <= 0
      Rails.logger.debug "#{media_files_count} media files left to analyze"
      return enqueue_next subject_id
    elsif media_files_count >= 1
      media_files = media_files_rel.limit(remaining_batch_size).to_a
      Rails.logger.debug "Analyzing #{media_files.length} media files"
      analyze_media_files media_files
    end

    if media_files_count > BATCH_SIZE
      Rails.logger.debug "#{media_files_count - remaining_batch_size} media files left to analyze"
      return enqueue_next subject_id
    end

    finish_analysis &block

    # TODO analysis: save media scan analyzed_at when analysis complete
  end

  private

  def self.finish_analysis &block
    block.call if block
  end

  def self.enqueue_next subject_id
    enqueue_after_transaction self, subject_id
  end

  def self.analyze_nfo_file nfo_file

    nfo_file = MediaFile.includes(:directory, :media_url).find nfo_file_id
    files_counts_updates = {}

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
        link_or_unlink_files relation: directory_files_rel, files_counts_updates: files_counts_updates
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

    MediaDirectory.apply_tracked_files_counts updates: files_counts_updates
  end

  def self.analyze_media_files media_files
    files_counts_updates = {}
    affected_media_urls = Set.new

    while media_files.any?

      file = media_files.shift
      nfo_files = nfo_files_for_directory directory: file.directory

      directory_files = media_files.select{ |f| f.directory == file.directory }
      media_files -= directory_files

      directory_files_rel = MediaFile.where id: directory_files.collect(&:id).unshift(file.id)

      if nfo_files.length == 1 && nfo_files.first.media_url
        # If exactly one NFO file applies to this directory and it is linked,
        # link the current file and all files in that directory to the same media
        # as the NFO file.
        link_or_unlink_files relation: directory_files_rel, media_url: nfo_files.first.media_url, files_counts_updates: files_counts_updates
        affected_media_urls << nfo_files.first.media_url
      else
        # If no NFO file or multiple NFO files apply to this directory, or if
        # the NFO file that applies is not linked, mark all files in that directory
        # as unlinked.
        affected_media_urls += media_files.collect &:media_url
        link_or_unlink_files relation: directory_files_rel, files_counts_updates: files_counts_updates
      end
    end

    MediaDirectory.apply_tracked_files_counts updates: files_counts_updates

    # TODO: update media ownerships
    #affected_media_urls.each do |media_url|
    #  UpdateMediaOwnershipsJob.enqueue media_url: media_url, user: scan.source.user, event: scan.last_scan_event
    #end
  end

  def self.media_files_for_directory directory:
    directory.child_files do |rel|
      rel.where 'media_files.type = ? AND media_files.deleted = ? AND media_files.extension != ?', MediaFile.name, false, 'nfo'
    end
  end

  def self.nfo_files_for_directory directory:
    directory_files_rel = directory.child_files do |rel|
      rel.where 'media_files.type = ? AND media_files.deleted = ? AND media_files.extension = ?', MediaFile.name, false, 'nfo'
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
      link_or_unlink_files relation: directory_files_rel, files_counts_updates: files_counts_updates
      return
    end

    scan_path = source.scan_paths.to_a.find do |sp|
      nfo_file.path.index("#{sp.path}/") == 0
    end

    media_url = MediaUrl.resolve url: nfo_file.url, default_category: scan_path.try(:category), save: true, creator: source.user
    if media_url.blank?
      MediaDirectory.track_linked_files_counts updates: files_counts_updates, linked: false, changed_file: nfo_file if nfo_file.linked?
      nfo_file.mark_as_invalid!
      link_or_unlink_files relation: directory_files_rel, files_counts_updates: files_counts_updates
      return
    end

    MediaDirectory.track_linked_files_counts updates: files_counts_updates, linked: true, changed_file: nfo_file unless nfo_file.linked?

    nfo_file.media_url = media_url
    nfo_file.mark_as_linked!

    link_or_unlink_files relation: directory_files_rel, media_url: media_url, files_counts_updates: files_counts_updates
  end

  def self.link_or_unlink_files relation:, media_url: nil, files_counts_updates:
    MediaDirectory.track_linked_files_counts updates: files_counts_updates, changed_relation: relation, linked: media_url.present?
    relation.update_all analyzed: true, media_url_id: media_url.try(:id)
  end
end
