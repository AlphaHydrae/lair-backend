class JobError < ActiveRecord::Base
  belongs_to :cause, polymorphic: true
  after_create{ update_job_errors_count 1 }
  after_destroy{ update_job_errors_count -1 }

  validates :cause, presence: true
  validates :queue, presence: true, length: { maximum: 20 }
  validates :error_message, presence: true
  validates :error_backtrace, presence: true

  def update_job_errors_count by
    cause_class = cause_type.constantize
    return unless cause_class.column_names.include? 'job_errors_count'
    cause_class.update_counters cause_id, job_errors_count: by
  end
end
