module ResourceWithJobs
  extend ActiveSupport::Concern

  included do
    attr_accessor :job_to_queue
    after_commit :auto_queue_job
  end

  def auto_queue_job
    if job_to_queue
      send "queue_#{job_to_queue}_job"
    end

    self.job_to_queue = nil
  end

  def method_missing method, *args, &block
    if match = method.to_s.match(/^set_([a-z0-9]+(?:_[a-z0-9]+)*)_job_required$/)
      if self.class.auto_queueable_jobs.include? match[1].to_sym
        self.job_to_queue = match[1]
      else
        raise "No #{match[1]} job defined"
      end
    else
      super method, *args, &block
    end
  end

  module ClassMethods
    def auto_queueable_jobs *args
      if args.empty?
        @auto_queueable_jobs || []
      else
        @auto_queueable_jobs = args.collect &:to_sym
      end
    end
  end
end
