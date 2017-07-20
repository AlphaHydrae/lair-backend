class AnalyzeMediaFileJob < AbstractAnalyzeMediaFilesJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue file
    log_queueing "media file #{file.api_id}"
    enqueue_after_transaction self, file.id
  end

  def self.lock_workers *args
    :media
  end

  def self.perform media_file_id
    # TODO analysis: create media:analysis:file event (in controller)
    media_file = MediaFile.includes(source: :user).find id: media_file_id
    relation = media_file_rel.where id: media_file_id, analyzed: false
    perform_analysis relation: relation, job_args: [ media_file_id ], event: nil, analysis_event_type: 'media:analysis:file', analysis_user: media_file.source.user, cause: media_file
  end
end
