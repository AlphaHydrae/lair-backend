module TrackedImmutableResource
  extend ActiveSupport::Concern
  include TrackedResource

  included do
    before_update{ raise "Resource is immutable!" }
  end
end
