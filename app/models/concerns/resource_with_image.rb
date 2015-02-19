module ResourceWithImage
  extend ActiveSupport::Concern

  # FIXME: delete image along with resource (if it has no other links)
  # FIXME: delete old image if image is updated and old image has no other links
  included do
    belongs_to :image, autosave: true
    has_many :image_searches, as: :imageable
  end

  def default_image_search_query
    raise NotImplementedError, "#{self.class.name} does not implement #default_image_search"
  end

  def last_image_search
    last_image_search_rel.first
  end

  def last_image_search!
    last_image_search_rel.first!
  end

  private

  def last_image_search_rel
    image_searches.order('created_at desc').limit(1)
  end
end
