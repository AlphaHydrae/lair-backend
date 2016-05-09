class ApplicationJob
  def self.enqueue_after_transaction *args
    Resque.enqueue *args
  end

  def self.after_transaction
    ActiveRecord::Base.after_transaction do
      yield if block_given?
    end
  end

  def self.create_job_event trackable, user
    Event.new(event_type: 'job', user: user, trackable: trackable, trackable_api_id: trackable.api_id).tap &:save!
  end
end
