module ResourceWithTags
  extend ActiveSupport::Concern

  def tags
    super || {}
  end
end
