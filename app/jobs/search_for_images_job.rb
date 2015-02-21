class SearchForImagesJob
  @queue = :low

  def self.enqueue imageable, options = {}
    Resque.enqueue self, imageable.id, imageable.class.name, options = {}
  end

  def self.perform imageable_id, imageable_type, options = {}
    imageable = imageable_type.constantize.where(id: imageable_id).first
    ImageSearchHelper.search_images_for imageable, HashWithIndifferentAccess.new(options) if imageable.present?
  end
end
