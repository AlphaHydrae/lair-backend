module ResourceWithImage
  extend ActiveSupport::Concern
  include ApiImageableHelper

  # FIXME: delete image along with resource (if it has no other links)
  # FIXME: delete old image if image is updated and old image has no other links
  # TODO: delete image searches when image is set
  included do
    belongs_to :image, autosave: true
    belongs_to :main_image_search, class_name: 'ImageSearch'
    has_many :image_searches, as: :imageable
  end

  def default_image_search_query
    raise NotImplementedError, "#{self.class.name} does not implement #default_image_search"
  end

  def main_image_search!
    raise ActiveRecord::RecordNotFound, "Couldn't find last image search of #{self.class.name} #{id}" unless main_image_search.present?
    main_image_search
  end
end
