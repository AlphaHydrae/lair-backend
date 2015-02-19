module ApiImageSearchHelper
  def search_images_for imageable, options = {}

    force = options[:force]
    last_search = force ? nil : imageable.last_image_search

    # if there is no previous search of if the criteria are different, a new search must be performed
    if last_search.blank? || (params.key?(:query) && params[:query].to_s != last_search.query)

      # resolve search parameters
      query = params[:query].present? ? params[:query].to_s : last_search.try(:query) || imageable.default_image_search_query

      # perform search
      search_result = BingSearch.images query

      # enforce rate limit
      set_rate_limit_headers search_result.rate_limit
      search_result.rate_limit.enforce!

      # save results
      ImageSearch.new(imageable: imageable, engine: 'bing', query: query, results: search_result.results).tap(&:save!)

    # otherwise, the results from the previous search are returned
    else

      # add rate limit information
      set_rate_limit_headers BingSearch.rate_limit_status

      # return existing results
      last_search
    end
  end

  private

  def set_rate_limit_headers rate_limit
    header 'X-RateLimit-Total', rate_limit.total.to_s
    header 'X-RateLimit-Remaining', rate_limit.remaining.to_s
    header 'X-RateLimit-Reset', rate_limit.reset_time.to_i.to_s
  end
end
