module ResourceWithImage
  extend ActiveSupport::Concern
  include ApiImageableHelper

  # FIXME: delete image along with resource (if it has no other links)
  # FIXME: delete old image if image is updated and old image has no other links
  included do
    after_save :clean_up_image_searches

    belongs_to :image, autosave: true
    belongs_to :last_image_search, class_name: 'ImageSearch'
    has_many :image_searches, as: :imageable
  end

  def default_image_search_query
    raise NotImplementedError, "#{self.class.name} does not implement #default_image_search"
  end

  private

  def clean_up_image_searches
    image_id_change = changes[:image_id]
    ImageSearch.where(imageable: self).delete_all if image_id_change.try :[], 1
    true
  end
end
