module BingSearch
  def self.images query, options = {}
    rate_limit = RateLimitStatus.new :bingSearch
    search_result = ImageSearchResult.new :bing, rate_limit

    check_rate_limit! rate_limit
    return search_result if rate_limit.exceeded?

    res = HTTParty.get image_search_url, query: { '$format' => 'json', 'Query' => "'#{query}'" }, headers: { 'Accept' => 'application/json', 'Authorization' => authorization }
    res = JSON.parse res.body

    search_result.results = res['d']['results'].collect do |result|
      {
        url: result['MediaUrl'],
        contentType: result['ContentType'],
        width: result['Width'],
        height: result['Height'],
        size: result['FileSize']
      }.select{ |k,v| v.present? }.tap do |h|
        if result['Thumbnail'].present?
          h[:thumbnail] = {
            url: result['Thumbnail']['MediaUrl'],
            contentType: result['Thumbnail']['ContentType'],
            width: result['Thumbnail']['Width'],
            height: result['Thumbnail']['Height'],
            size: result['Thumbnail']['FileSize']
          }.select{ |k,v| v.present? }
        end
      end
    end

    search_result
  end

  def self.rate_limit_status
    rate_limit = RateLimitStatus.new :bingSearch

    res = $redis.multi do
      $redis.get 'rateLimit:bingSearch'
      $redis.ttl 'rateLimit:bingSearch'
    end

    rate_limit.total = config[:rate_limit_value].to_i
    rate_limit.current = res[0].try(:to_i) || 0
    rate_limit.duration = config[:rate_limit_duration].to_i

    # ttl will be either a number of seconds or negative if the key doesn't exist or is not set to expire
    rate_limit.ttl = res[1].to_i
    rate_limit.ttl = rate_limit.duration if rate_limit.ttl < 0

    rate_limit
  end

  private

  def self.check_rate_limit! rate_limit
    duration = config[:rate_limit_duration].to_i

    res = $redis.multi do
      # set rate limit to 0 with ttl (if it doesn't exist)
      $redis.set 'rateLimit:bingSearch', 0, nx: true, ex: duration
      # increment rate limit by 1
      $redis.incr 'rateLimit:bingSearch'
      # also get remaining ttl
      $redis.ttl 'rateLimit:bingSearch'
    end

    rate_limit.total = config[:rate_limit_value].to_i
    rate_limit.current = res[1]
    rate_limit.duration = duration
    rate_limit.ttl = res[2]
  end

  def self.image_search_url
    base_url = config[:url]
    "#{base_url}/Image"
  end

  def self.authorization
    key = Rails.application.secrets.azure_account_key
    encoded = Base64.strict_encode64 "#{key}:#{key}"
    "Basic #{encoded}"
  end

  def self.config
    @config ||= HashWithIndifferentAccess.new(Rails.application.config_for(:services)['bing_search'])
  end
end
