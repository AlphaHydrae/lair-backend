class RateLimit
  attr_accessor :service
  attr_accessor :total
  attr_accessor :current
  attr_accessor :duration
  attr_accessor :ttl

  def initialize service
    @service = service
  end

  def exceeded?
    current > total
  end

  def enforce!
    raise RateLimitError.new(limit_exceeded_message, headers: limit_exceeded_headers) if exceeded?
  end

  def remaining
    exceeded? ? 0 : total - current
  end

  def reset_time
    Time.now + ttl
  end

  # TODO: move this to application
  def self.check_rate_limit service
    limit = new service
    config = Rails.application.service_config service
    redis_key = "rateLimit:#{service}"

    res = $redis.multi do
      $redis.get redis_key
      $redis.ttl redis_key
    end

    limit.total = config[:rate_limit_value].to_i
    limit.current = res[0].try(:to_i) || 0
    limit.duration = config[:rate_limit_duration].to_i

    # ttl will be either a number of seconds or negative if the key doesn't exist or is not set to expire
    limit.ttl = res[1].to_i
    limit.ttl = limit.duration if limit.ttl < 0

    limit
  end

  def self.check_rate_limit! service
    limit = new service
    redis_key = "rateLimit:#{service}"
    config = Rails.application.service_config service
    duration = config[:rate_limit_duration].to_i

    res = $redis.multi do
      # set rate limit to 0 with ttl (if it doesn't exist)
      $redis.set redis_key, 0, nx: true, ex: duration
      # increment rate limit by 1
      $redis.incr redis_key
      # also get remaining ttl
      $redis.ttl redis_key
    end

    limit.total = config[:rate_limit_value].to_i
    limit.current = res[1]
    limit.duration = duration
    limit.ttl = res[2]

    limit
  end

  private

  def limit_exceeded_message
    "Rate limit of #{@total} per #{@duration}s exceeded for search engine #{@service} (#{@current} requests were made; reset will occur in #{@ttl}s)"
  end

  def limit_exceeded_headers
    {
      'X-RateLimit-Total' => @total.to_s,
      'X-RateLimit-Remaining' => 0,
      'X-RateLimit-Reset' => reset_time.to_i.to_s
    }
  end
end
