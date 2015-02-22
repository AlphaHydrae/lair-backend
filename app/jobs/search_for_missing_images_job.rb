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
    items = Item.where('image_id IS NULL AND last_image_search_id IS NULL').limit(n).to_a
    items.each.with_index do |item,i|
      ns = interval * i
      Resque.enqueue_in ns.seconds, SearchForImagesJob, item.id, item.class.name
    end

    if items.length < n
      parts = ItemPart.where('image_id IS NULL AND last_image_search_id IS NULL').limit(n - items.length).to_a
      parts.each.with_index do |part,i|
        ns = interval * i
        Resque.enqueue_in ns.seconds, SearchForImagesJob, part.id, part.class.name
      end
    end
  end
end
