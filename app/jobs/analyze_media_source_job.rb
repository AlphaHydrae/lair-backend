class AnalyzeRemainingMediaFilesJob < AbstractAnalyzeMediaFilesJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue source
    log_queueing "media source #{source.api_id}"
    enqueue_after_transaction self, source.id
  end

  def self.lock_workers *args
    :media
  end

  def self.perform media_source_id
    # TODO analysis: create media:analysis:source event (in controller)
    media_source = MediaSource.find media_source_id
    files_to_analyze_rel = MediaFile.where source_id: media_source_id, analyzed: false

    perform_analysis relation: files_to_analyze_rel, job_args: [ media_source_id ], event: nil, cause: media_source
  end
end
