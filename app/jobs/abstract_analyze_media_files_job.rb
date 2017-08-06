require 'resque/plugins/workers/lock'

# TODO analysis: parallelize by locking media url creation and using first-level directories
class AbstractAnalyzeMediaFilesJob < ApplicationJob
  BATCH_SIZE = 100

  def self.perform_analysis relation:, job_args:, event:, analysis_event_type:, analysis_user:, cause:, clear_errors: true, &block
    result = nil

    job_transaction cause: cause, clear_errors: clear_errors do
      analysis_event = ::Event.new(cause: event, event_type: analysis_event_type, user: analysis_user, trackable: cause, trackable_api_id: cause.api_id).tap &:save!
      Rails.application.with_current_event analysis_event do
        result = AnalyzeMediaFiles.new(relation: relation, user: analysis_user).perform &block
      end
    end

    enqueue_next *job_args if result == :continue_job_later
  end

  def self.enqueue_next *job_args
    enqueue_after_transaction self, *job_args
  end

  private

  class AnalyzeMediaFiles
    def initialize relation:, user:
      @relation = relation
      @user = user
      @counts_tracker = MediaFileCountsTracker.new
    end

    def perform &block
      relation = @relation.preload :directory, :media_url, source: :user

      # Analyze NFO files first
      nfo_files_rel = relation.where extension: 'nfo'
      nfo_files_count = nfo_files_rel.count
      if nfo_files_count >= 1
        nfo_files = nfo_files_rel.limit(BATCH_SIZE).to_a
        Rails.logger.debug "Analyzing #{nfo_files.length} NFO files"
        analyze_nfo_files nfo_files
      else
        Rails.logger.debug 'No more NFO files to analyze'
      end

      if nfo_files_count > BATCH_SIZE
        Rails.logger.debug "#{nfo_files_count - BATCH_SIZE} NFO files left to analyze"
        return :continue_job_later
      end

      remaining_batch_size = BATCH_SIZE - nfo_files_count

      # Then analyze remaining non-NFO files
      media_files_rel = relation.where('extension IS DISTINCT FROM ?', 'nfo').order 'path'
      media_files_count = media_files_rel.count
      if media_files_count <= 0
        Rails.logger.debug 'No more media files to analyze'
        return finish_analysis &block
      elsif remaining_batch_size <= 0
        Rails.logger.debug "#{media_files_count} media files left to analyze"
        return :continue_job_later
      elsif media_files_count >= 1
        media_files = media_files_rel.limit(remaining_batch_size).to_a
        Rails.logger.debug "Analyzing #{media_files.length} media files"
        analyze_media_files media_files
      end

      if media_files_count > remaining_batch_size
        Rails.logger.debug "#{media_files_count - remaining_batch_size} media files left to analyze"
        return :continue_job_later
      end

      finish_analysis &block
    end

    def finish_analysis &block
      block.call if block
    end

    def analyze_nfo_files nfo_files
      affected_media_urls = Set.new
      nfo_files_by_directory = {}
      prepare_nfo_files_by_directory nfo_files: nfo_files

      while nfo_files.any?

        nfo_file = nfo_files.shift
        Rails.logger.debug "Analyzing NFO file #{nfo_file.path} (#{nfo_file.id})"

        directory = nfo_file.directory
        affected_media_urls << nfo_file.media_url if nfo_file.media_url
        other_nfo_files = other_nfo_files_in_directory directory: directory, nfo_file: nfo_file

        # First, analyze and link/unlink the NFO file itself
        process_nfo_file nfo_file: nfo_file, other_nfo_files: other_nfo_files

        effective_nfo_file = nil
        update_child_files = false

        if nfo_file.nfo_active?
          # If the NFO file is active (i.e. it is valid and there are no other NFO files in its directory), link media files to it
          effective_nfo_file = nfo_file
          update_child_files = true
        elsif nfo_file.deleted? && other_nfo_files.length == 1 && other_nfo_files.first.analyzed?
          # If the NFO file was deleted but there is exactly one another NFO file in its directory, link media files to that file
          effective_nfo_file = other_nfo_files.first
          update_child_files = true
        elsif nfo_file.deleted? && other_nfo_files.blank?
          # If the NFO file was deleted and there is no other NFO file in its directory, unlink media files...
          effective_nfo_file = nil
          update_child_files = true
          if nfo_file.depth >= 2
            # ... unless there is an active NFO file in a parent directory
            parent_nfo_files = parent_nfo_files_for_directory directory: directory
            effective_nfo_file = parent_nfo_files.first if parent_nfo_files.length == 1 && parent_nfo_files.first.nfo_active?
          end
        else
          # Otherwise, unlink media files in the directory (unless there are other NFO files to analyze)
          effective_nfo_file = nil
          update_child_files = other_nfo_files.all? &:analyzed?
        end

        if update_child_files
          effective_media_url = effective_nfo_file.try :media_url
          affected_media_urls << effective_media_url if effective_media_url

          affected_child_directories = directory.child_files do |rel|
            rel.where 'media_files.type = ? AND media_files.immediate_nfo_files_count <= 0', MediaDirectory.name
          end

          affected_directory_ids = affected_child_directories.collect(&:id).unshift directory.id
          affected_files_rel = MediaFile.where('media_files.deleted = ? AND media_files.type = ? AND media_files.extension IS DISTINCT FROM ? AND media_files.directory_id IN (?)', false, MediaFile.name, 'nfo', affected_directory_ids)
          link_or_unlink_files relation: affected_files_rel, media_url: effective_media_url
        end
      end

      @counts_tracker.apply!

      affected_media_urls.each do |media_url|
        UpdateMediaOwnershipsJob.enqueue media_url: media_url, user: @user if media_url.present?
      end
    end

    # TODO analysis: automatically mark all non-NFO deleted media files as analyzed
    def analyze_media_files media_files
      affected_media_urls = Set.new

      while media_files.any?

        file = media_files.shift

        directory_files = media_files.select{ |f| f.directory == file.directory }
        directory_files_rel = MediaFile.where id: directory_files.collect(&:id).unshift(file.id)

        affected_media_urls += directory_files.collect(&:media_url).select &:present?
        media_files -= directory_files

        nfo_file = nfo_file_for_directory directory: file.directory
        if nfo_file
          # If exactly one NFO file applies to this directory, link the media files
          link_or_unlink_files relation: directory_files_rel, media_url: nfo_file.media_url
          affected_media_urls << nfo_file.media_url if nfo_file.media_url
        else
          # If no valid NFO file applies to this directory, unlink the media files
          link_or_unlink_files relation: directory_files_rel
        end
      end

      @counts_tracker.apply!

      affected_media_urls.each do |media_url|
        UpdateMediaOwnershipsJob.enqueue media_url: media_url, user: @user
      end
    end

    def prepare_nfo_files_by_directory nfo_files:
      directory_ids = nfo_files.collect(&:directory_id).uniq
      extra_nfo_files = MediaFile.where('media_files.deleted = ? AND media_files.extension = ? AND media_files.directory_id IN (?) AND media_files.id NOT IN (?)', false, 'nfo', directory_ids, nfo_files.collect(&:id)).to_a
      @nfo_files_by_directory = (nfo_files + extra_nfo_files).inject({}) do |memo,nfo_file|
        memo[nfo_file.directory_id] ||= []
        memo[nfo_file.directory_id] << nfo_file
        memo
      end
    end

    def other_nfo_files_in_directory directory:, nfo_file:
      raise "Expected NFO files for directory #{directory.api_id} to have been prepared" unless @nfo_files_by_directory[directory.id]
      (@nfo_files_by_directory[directory.id] - [ nfo_file ]).reject &:deleted?
    end

    def parent_nfo_files_for_directory directory:
      parent_directory_with_nfo_files = directory.parent_directories{ |rel| rel.where 'immediate_nfo_files_count <= 0' }.order('depth').first
      MediaFile.where('media_files.deleted = ? AND media_files.extension = ? AND media_files.directory_id = ?', false, 'nfo', parent_directory_with_nfo_files.id).to_a
    end

    def nfo_file_for_directory directory:

      nfo_files = nfo_files_in_directory directory: directory
      if nfo_files.present?
        return nfo_files.length == 1 ? nfo_files.first : nil
      end

      parent_nfo_files = parent_nfo_files_for_directory directory: directory
      return parent_nfo_files.length == 1 ? parent_nfo_files.first : nil
    end

    def nfo_files_in_directory directory:
      MediaFile.where('media_files.deleted = ? AND media_files.extension = ? AND media_files.directory_id = ?', false, 'nfo', directory.id).to_a
    end

    def process_nfo_file nfo_file:, other_nfo_files:
      nfo_file_was_linked = nfo_file.media_url.present?

      unless nfo_file.deleted?
        if nfo_file.url
          scan_path = nfo_file.source.scan_paths.to_a.find do |sp|
            nfo_file.path.index("#{sp.path}/") == 0
          end

          nfo_file.media_url = MediaUrl.resolve url: nfo_file.url, default_category: scan_path.try(:category), save: true, creator: nfo_file.source.user
        else
          nfo_file.media_url = nil
        end

        if nfo_file.url.blank? || nfo_file.media_url.blank?
          nfo_file.nfo_error = 'invalid'
        elsif other_nfo_files.any?
          nfo_file.nfo_error = 'duplicate'
        else
          nfo_file.nfo_error = nil
        end
      end

      nfo_file.analyzed = true
      @counts_tracker.track_analysis file: nfo_file, analyzed: nfo_file.analyzed if nfo_file.analyzed_changed?

      nfo_file.save!

      if nfo_file.media_url.present? != nfo_file_was_linked
        @counts_tracker.track_linking file: nfo_file, linked: nfo_file.media_url.present?
      end
    end

    def link_or_unlink_files relation:, media_url: nil
      @counts_tracker.track_linking relation: relation, linked: media_url.present?
      @counts_tracker.track_analysis relation: relation, analyzed: true
      relation.update_all analyzed: true, media_url_id: media_url.try(:id)
    end
  end
end
