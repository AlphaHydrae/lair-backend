module TrackedResource
  extend ActiveSupport::Concern

  included do
    attr_writer :deleter
    attr_accessor :creator_optional

    after_create :track_create
    after_destroy :track_destroy

    belongs_to :creator, class_name: 'User'
    has_many :events, as: :trackable

    validates :creator, presence: { unless: :creator_optional }
  end

  def cache_previous_version
    policy = Pundit.policy! :app, self
    @cached_previous_version = policy.serializer.serialize
  end

  def creator= creator
    super creator
    self.updater ||= creator if respond_to? :updater=
  end

  def deleter
    user = @deleter || Rails.application.destroy_user
    raise "Destroyer user is not set!" unless user
    user
  end

  private

  def cached_previous_version
    raise "Previous version was not cached!" unless @cached_previous_version
    @cached_previous_version
  end

  def track_create
    track :create, creator
  end

  def track_destroy
    track :delete, deleter, true
  end

  def track event_type, user, previous_version = false
    event = Event.new event_type: event_type, user: user, trackable: self, trackable_api_id: api_id
    event.previous_version = cached_previous_version if previous_version
    event.save!
  end
end
