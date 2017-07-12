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
    relation = MediaFile.where id: media_file_id, analyzed: false
    job_transaction cause: relation.first, clear_errors: true do
      perform_analysis relation: relation, subject_id: media_file_id
    end
  end
end
