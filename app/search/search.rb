module Search
  def self.engine name = nil
    return BingSearch unless name

    case name.to_sym
    when :bingSearch
      BingSearch
    when :googleCustomSearch
      GoogleCustomSearch
    else
      raise "Unknown search engine #{name.inspect}"
    end
  end
end
