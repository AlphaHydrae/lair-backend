module ResourceWithImage
  extend ActiveSupport::Concern
  include ApiImageableHelper

  # FIXME: delete image along with resource (if it has no other links)
  # FIXME: delete old image if image is updated and old image has no other links
  # TODO: delete image searches when image is set
  included do
    belongs_to :image, autosave: true
    belongs_to :last_image_search, class_name: 'ImageSearch'
    has_many :image_searches, as: :imageable
  end

  def default_image_search_query
    raise NotImplementedError, "#{self.class.name} does not implement #default_image_search"
  end

  def last_image_search!
    raise ActiveRecord::RecordNotFound, "Couldn't find last image search of #{self.class.name} #{id}" unless last_image_search.present?
    last_image_search
  end

  def add_image_to_builder json, options = {}
    if image.present?
      json.image image.to_builder
    elsif options[:image_from_search] && last_image_search.present? && last_image_search.results?
      json.image Image.new.fill_from_api_data(last_image_search.results.first.with_indifferent_access).to_builder
    end
  end
end
