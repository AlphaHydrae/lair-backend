class LairError < StandardError
  attr_reader :reason
  attr_reader :http_status_code
  attr_reader :headers

  def initialize msg = nil, options = {}
    super msg
    @reason = options[:reason]
    @http_status_code = options[:http_status_code]
    @headers = {}
  end
end

class AuthError < LairError
  def initialize msg = nil, options = {}
    options[:http_status_code] ||= 401
    super msg, options
  end
end

class RateLimitError < LairError
  def initialize msg = nil, options = {}
    options[:http_status_code] ||= 429
    super msg, options
  end
end
