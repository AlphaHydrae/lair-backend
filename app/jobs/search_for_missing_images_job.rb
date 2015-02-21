class SearchForMissingImagesJob
  @queue = :low

  def self.enqueue options = {}
    Resque.enqueue self, options
  end

  def self.perform options = {}

    options = options.with_indifferent_access
    n = options.fetch :n, 1
    interval = options.fetch :interval, 5

    # FIXME: check image search rate limit and only schedule jobs if it is not exceeded
    items = Item.joins("LEFT OUTER JOIN image_searches ON image_searches.imageable_id = items.id AND image_searches.imageable_type = '#{Item.name}'").where('items.image_id IS NULL AND image_searches.id IS NULL').limit(n).to_a
    items.each.with_index do |item,i|
      ns = interval * i
      Resque.enqueue_in ns.seconds, SearchForImagesJob, item.id, item.class.name
    end
  end
end
