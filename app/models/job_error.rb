class JobError < ActiveRecord::Base
  belongs_to :cause, polymorphic: true, counter_cache: :job_errors_count

  validates :cause, presence: true
  validates :queue, presence: true, length: { maximum: 20 }
  validates :error_message, presence: true
  validates :error_backtrace, presence: true
end
