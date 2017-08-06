class AnalyzeMediaSourceJob < AbstractAnalyzeMediaFilesJob
  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue source, event
    log_queueing "media source #{source.api_id}"
    enqueue_after_transaction self, source.id, event.id
  end

  def self.lock_workers *args
    :media
  end

  def self.perform media_source_id, event_id
    media_source = MediaSource.includes(:user).find media_source_id
    event = ::Event.find event_id
    files_to_analyze_rel = MediaFile.where source_id: media_source_id, analyzed: false

    finished = false
    perform_analysis relation: files_to_analyze_rel, job_args: [ media_source_id, event_id ], event: event, analysis_event_type: 'media:analysis:source', analysis_user: media_source.user, cause: media_source do
      unanalyzed_deleted_files = MediaFile.where(source: media_source).where deleted: true, analyzed: false
      unanalyzed_deleted_files.update_all analyzed: true
      finished = true
    end

    FixMediaFileCountsJob.enqueue source: media_source, event: event if finished
  end
end
