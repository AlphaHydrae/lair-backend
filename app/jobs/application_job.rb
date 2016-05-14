class ApplicationJob
  def self.enqueue_after_transaction *args
    Resque.enqueue *args
  end

  def self.after_transaction
    ActiveRecord::Base.after_transaction do
      yield if block_given?
    end
  end

  def self.log_queueing description
    Rails.logger.debug "Queueing #{name} for #{description}"
  end

  def self.save_error! cause:, error: $!
    JobError.new(cause: cause, job: name, queue: @queue, error_message: error.message, error_backtrace: error.backtrace.join("\n")).tap &:save!
  end

  def self.delete_job_errors cause:
    cause.class.transaction do
      JobError.where(cause: cause).delete_all
      cause.update_columns job_errors_count: 0
    end
  end

  def self.job_transaction cause:, rescue_event: nil, clear_errors: false

    delete_job_errors cause: cause if clear_errors

    JobError.transaction do
      yield if block_given?
    end

  rescue

    if rescue_event
      cause.reload
      cause.send rescue_event
    end

    save_error! cause: cause
  end
end
