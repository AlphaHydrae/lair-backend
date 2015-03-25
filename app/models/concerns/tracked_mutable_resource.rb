module TrackedMutableResource
  extend ActiveSupport::Concern
  include TrackedResource

  included do
    after_update :track_update

    belongs_to :updater, class_name: 'User'
  end

  private

  def track_update
    track :update, updater, true
  end
end
