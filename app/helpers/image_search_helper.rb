module ImageSearchHelper
  def self.search_images_for imageable, options = {}

    force = options[:force]
    last_search = force ? nil : imageable.last_image_search

    # if there is no previous search of if the criteria are different, a new search must be performed
    if last_search.blank? || (options.key?(:query) && options[:query].to_s != last_search.query)

      # perform search
      query = options[:query].present? ? options[:query].to_s : last_search.try(:query) || imageable.default_image_search_query
      search = ImageSearch.new imageable: imageable, user: options[:user], query: query
      BingSearch.images! search

      # save results
      search.save! unless search.rate_limit.exceeded?
      search
    else

      # otherwise, return the results from the previous search with rate limit information
      last_search.tap{ |s| s.rate_limit = BingSearch.rate_limit }
    end
  end

  module Api
    def search_images_for imageable, options = {}
      options.reverse_merge! params.slice(:query).merge(user: current_user)
      search = ImageSearchHelper.search_images_for imageable, options
      search.rate_limit.enforce! if search.results.nil?
      set_image_search_rate_limit_headers search.rate_limit
      search
    end

    private

    def set_image_search_rate_limit_headers rate_limit
      header 'X-RateLimit-Total', rate_limit.total.to_s
      header 'X-RateLimit-Remaining', rate_limit.remaining.to_s
      header 'X-RateLimit-Reset', rate_limit.reset_time.to_i.to_s
    end
  end
end
