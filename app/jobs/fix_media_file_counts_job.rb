require 'resque/plugins/workers/lock'

class FixMediaFileCountsJob < ApplicationJob
  extend Resque::Plugins::Workers::Lock

  BATCH_SIZE = 250

  @queue = :low

  def self.enqueue source:, event:
    log_queueing "media source #{source.api_id}"
    enqueue_after_transaction self, source.id, event.id
  end

  def self.lock_workers source_id, event_id
    [ :media, "media-#{source_id}" ]
  end

  def self.perform source_id, event_id
    source = MediaSource.find source_id
    event = ::Event.find event_id

    job_transaction cause: source do
      Rails.application.with_current_event event do
        FixMediaFileCounts.new(source: source).perform
      end
    end
  end

  private

  class FixMediaFileCounts
    COUNT_TYPES = %i(files_count nfo_files_count linked_files_count)
    IMMEDIATE_COUNT_TYPES = %i(nfo_files_count)

    def initialize source:
      @source = source
      @counts_by_directory_id = Hash.new do |hash,key|
        hash[key] = {
          files_count: 0,
          nfo_files_count: 0,
          linked_files_count: 0
        }
      end
    end

    def perform
      Rails.logger.debug "Fixing file counts for media source #{@source.name} (#{@source.api_id})"

      source_directories_rel = MediaDirectory.where source: @source, deleted: false
      max_depth = source_directories_rel.maximum :depth

      while max_depth >= 0
        Rails.logger.debug "Fixing file counts for directories at depth #{max_depth}"

        source_directories_rel.select(:id).where(depth: max_depth).find_in_batches batch_size: BATCH_SIZE do |directories|
          directories_with_counts(directories: directories).each do |directory|
            messages = []
            updates = {}

            COUNT_TYPES.each do |type|
              actual = directory.send type
              expected = directory.send("immediate_#{type}_verification") + pull_children_counts!(directory: directory, type: type)
              if actual != expected
                messages << "#{type} mismatch (#{actual} != #{expected})"
                updates[type] = expected
              end
            end

            IMMEDIATE_COUNT_TYPES.each do |type|
              actual = directory.send "immediate_#{type}"
              expected = directory.send "immediate_#{type}_verification"
              if actual != expected
                messages << "immediate_#{type} mismatch (#{actual} != #{expected})"
                updates["immediate_#{type}"] = expected
              end
            end

            unless updates.empty?
              Rails.logger.info "Fixing file counts for directory #{directory.path}: #{messages.join(', ')}"
              directory.update_columns updates
            end

            track_parent_counts directory: directory
          end
        end

        max_depth -= 1
      end
    end

    private

    def pull_children_counts! directory:, type:
      raise "Directory must be a #{MediaDirectory.name}, got #{directory.inspect}" unless directory.kind_of? MediaDirectory
      raise "Unknown count type #{type.inspect}" unless COUNT_TYPES.include? type

      @counts_by_directory_id[directory.id].delete(type).tap do
        @counts_by_directory_id.delete directory.id if @counts_by_directory_id[directory.id].empty?
      end
    end

    def track_parent_counts directory:
      raise "Directory must be a #{MediaDirectory.name}, got #{directory.inspect}" unless directory.kind_of? MediaDirectory

      if directory.depth >= 1
        COUNT_TYPES.each do |type|
          @counts_by_directory_id[directory.directory_id][type] += directory.send(type)
        end
      end
    end

    def directories_with_counts directories:
      counts_sql = <<-SQL
        media_files.*,
        COUNT(files_media_files.id) AS immediate_files_count_verification,
        SUM(CASE WHEN files_media_files.media_url_id IS NOT NULL THEN 1 ELSE 0 END) AS immediate_linked_files_count_verification,
        SUM(CASE WHEN files_media_files.extension = 'nfo' THEN 1 ELSE 0 END) AS immediate_nfo_files_count_verification
      SQL

      MediaDirectory.select(counts_sql).joins(:files).where('media_files.id IN (?) AND files_media_files.type = ? AND files_media_files.deleted = ?', directories.collect(&:id), MediaFile.name, false).group('media_files.id').to_a
    end
  end
end
