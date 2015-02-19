class RateLimitStatus
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
