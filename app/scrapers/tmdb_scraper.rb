class TmdbScraper < ApplicationScraper
  TMDB_API_URL = 'https://api.themoviedb.org/3'
  IMDB_URL_PATTERN = 'http://www.imdb.com/title/%{imdb_id}'
  MAX_SEARCH_RESULTS = 2

  def self.scraper
    :tmdb
  end

  def self.providers
    %i(imdb tmdb)
  end

  def self.search query:
    tmdb_config = get_tmdb_configuration

    results = search_tmdb_movies query: query

    if results.blank? && m = query.match(/^(.+)\s+\([^\)]+\)\s*$/)
      results = search_tmdb_movies query: m[1]
    end

    results = results[0, MAX_SEARCH_RESULTS] if results.length > MAX_SEARCH_RESULTS

    start = Time.now
    results.each do |result|
      result['imdb_id'] = get_tmdb_movie_imdb_id result
    end

    duration = (Time.now.to_f - start.to_f).round 3
    Rails.logger.debug %/Retrieved IMDB IDs for #{results.length} TMDb movies in #{duration}s/

    results.inject [] do |memo,result|
      next memo unless result['imdb_id'].present?

      imdb_url = IMDB_URL_PATTERN % { imdb_id: result['imdb_id'] }
      media_url = MediaUrl.resolve url: imdb_url
      next memo unless media_url && providers.collect(&:to_s).include?(media_url.provider.to_s)

      image_base_url = tmdb_config['images']['secure_base_url']

      poster_sizes = tmdb_config['images']['poster_sizes'].select{ |size| size.match /^w\d+$/i }.collect{ |size| size.sub(/^w/, '').to_i }
      image_size = poster_sizes.sort.reverse.find{ |size| size >= 200 && size <= 500 }
      image_size = image_size ? "w#{image_size}" : 'original'

      next memo unless image_base_url && result['poster_path']
      image_url = "#{image_base_url}#{image_size}#{result['poster_path']}"

      memo << {
        image: image_url,
        title: result['title'],
        url: media_url.url
      }
    end
  end

  def self.scraps? *args
    config[:enabled] && super(*args)
  end

  def self.scrap scrap
    tmdb_config = get_tmdb_configuration
    contents = find_imdb_movie scrap.media_url
    scrap.contents = JSON.dump contents.merge({ 'configuration': tmdb_config })
    scrap.content_type = 'application/json'
  end

  def self.expand scrap
  end

  def self.test media_url
    find_imdb_movie media_url
  end

  private

  def self.search_tmdb_movies query:

    start = Time.now

    res = query_tmdb_api path: 'search/movie', query: {
      'query' => Rack::Utils.escape(query.strip)
    }

    duration = (Time.now.to_f - start.to_f).round 3
    Rails.logger.debug %/TMDb search for "#{query}" performed in #{duration}s/

    JSON.parse(res.body)['results']
  end

  def self.get_tmdb_movie_imdb_id tmdb_movie
    res = query_tmdb_api path: "movie/#{tmdb_movie['id']}"
    JSON.parse(res.body)['imdb_id']
  end

  def self.find_imdb_movie media_url

    res = query_tmdb_api path: "find/#{media_url.provider_id}", query: { external_source: 'imdb_id' }
    result = JSON.parse res.body

    response_successful = result['movie_results'].kind_of?(Array) && result['movie_results'].length == 1
    if !response_successful
      raise "Received unexpected TMDb response with no single matching movie: #{res.body}"
    end

    res = query_tmdb_api path: "movie/#{result['movie_results'][0]['id']}", query: {
      append_to_response: 'alternative_titles,credits,images,keywords,release_dates,translations,videos'
    }

    JSON.parse res.body
  end

  def self.get_tmdb_configuration
    config = $redis.get 'tmdb:configuration'

    unless config
      res = query_tmdb_api path: 'configuration'
      $redis.set 'tmdb:configuration', res.body, ex: 1.day.to_i
      config = res.body
    end

    JSON.parse config
  end

  def self.query_tmdb_api path:, query: {}
    url = "#{TMDB_API_URL}/#{path}"
    Rails.logger.debug %/GET #{url}#{query.present? ? " #{query.inspect}" : ''}/
    res = HTTParty.get url, query: query.merge({ api_key: config[:api_key] })
    raise "TMDb API HTTP #{res.code}: #{res.body}" unless res.code >= 200 && res.code < 300
    res
  end

  def self.config
    Rails.application.service_config :tmdb
  end
end
