module BingSearch
  def self.images! search
    search.engine = :bing
    search.rate_limit = RateLimit.new :bing

    check_rate_limit! search.rate_limit
    return search if rate_limit.exceeded?

    res = HTTParty.get image_search_url, query: { '$format' => 'json', 'Query' => "'#{search.query}'" }, headers: { 'Accept' => 'application/json', 'Authorization' => authorization }
    res = JSON.parse res.body

    search.results = res['d']['results'].collect do |result|
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

    search
  end

  def self.rate_limit
    rate_limit = RateLimit.new :bing

    res = $redis.multi do
      $redis.get 'rateLimit:bing'
      $redis.ttl 'rateLimit:bing'
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
      $redis.set 'rateLimit:bing', 0, nx: true, ex: duration
      # increment rate limit by 1
      $redis.incr 'rateLimit:bing'
      # also get remaining ttl
      $redis.ttl 'rateLimit:bing'
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
