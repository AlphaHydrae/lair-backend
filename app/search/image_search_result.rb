class ImageSearchResult
  attr_accessor :engine
  attr_accessor :results
  attr_accessor :rate_limit

  def initialize engine, rate_limit = nil
    @engine = engine
    @rate_limit = rate_limit
  end
end
