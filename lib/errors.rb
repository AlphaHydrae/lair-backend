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

class ConflictError < LairError
  def initialize msg = nil, options = {}
    options[:http_status_code] ||= 409
    super msg, options
  end
end

class ValidationError < LairError
  attr_reader :errors

  def initialize msg = nil, options = {}
    options[:http_status_code] ||= 422
    super msg, options
    @errors = []
  end

  def add message, **args
    error = {
      message: message
    }

    error[:path] = args[:path] if args[:path]

    @errors << error
    error
  end

  def empty?
    @errors.empty?
  end

  def any? &block
    @errors.any? &block
  end

  def raise_if_any &block
    raise self if any?(&block)
  end
end

class RateLimitError < LairError
  def initialize msg = nil, options = {}
    options[:http_status_code] ||= 429
    super msg, options
  end
end
