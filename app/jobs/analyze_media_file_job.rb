class AnalyzeMediaFileJob < AbstractAnalyzeMediaFilesJob
  extend Resque::Plugins::Workers::Lock

  @queue = :high

  def self.enqueue file, event
    log_queueing "media file #{file.api_id}"
    enqueue_after_transaction self, file.id, event.id
  end

  def self.lock_workers *args
    :media
  end

  def self.perform media_file_id, event_id
    # TODO analysis: create media:analysis:file event (in controller)
    media_file = MediaFile.includes(source: :user).find media_file_id
    event = ::Event.find event_id
    relation = MediaFile.where id: media_file_id, analyzed: false
    perform_analysis relation: relation, job_args: [ media_file_id, event_id ], event: event, analysis_event_type: 'media:analysis:file', analysis_user: media_file.source.user, cause: media_file
  end
end
