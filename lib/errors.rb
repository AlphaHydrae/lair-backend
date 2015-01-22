
class LairError < StandardError
  attr_reader :reason
  attr_reader :http_status_code

  def initialize msg = nil, options = {}
    super msg
    @reason = options[:reason]
    @http_status_code = options[:http_status_code]
  end
end

class AuthError < LairError

  def initialize msg = nil, options = {}
    options[:http_status_code] ||= :unauthorized
    super msg, options
  end
end
