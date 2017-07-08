require 'resque/plugins/workers/lock'

class AnalyzeRemainingMediaFilesJob < ApplicationJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue scan:, first_id:, last_id:
    log_queueing "media scan #{scan.api_id} new media files with IDs between #{first_id} and #{last_id}"
    enqueue_after_transaction self, scan.id, first_id, last_id
  end

  def self.lock_workers scan_id, first_id, last_id
    :media
  end

  private
end
