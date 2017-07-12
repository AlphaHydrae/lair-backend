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
    media_source = MediaSource.find media_source_id
    job_transaction cause: media_source, clear_errors: true do
      perform_analysis relation: MediaFile.where(source_id: media_source_id, analyzed: false), subject_id: media_source_id
    end
  end
end
