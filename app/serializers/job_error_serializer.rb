class JobErrorSerializer < ApplicationSerializer
  def build json, options = {}
    json.job record.job
    json.queue record.queue
    json.message record.error_message
    json.stackTrace record.error_backtrace if record.error_backtrace.present?
    json.createdAt record.created_at.iso8601(3)
  end
end
