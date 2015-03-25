module BingSearch
  def self.images! search
    search.engine = :bingSearch
    search.check_rate_limit!
    return search if search.rate_limit.exceeded?

    res = HTTParty.get image_search_url, query: { '$format' => 'json', 'Query' => "'#{search.query}'" }, headers: { 'Accept' => 'application/json', 'Authorization' => authorization }

    # TODO: use custom exception
    raise "Image search failed with status code #{res.code}: #{res.body}" unless res.code == 200

    res = JSON.parse res.body

    search.results = res['d']['results'].collect do |result|
      {
        url: result['MediaUrl'],
        contentType: result['ContentType'],
        width: result['Width'].try(:to_i),
        height: result['Height'].try(:to_i),
        size: result['FileSize'].try(:to_i)
      }.select{ |k,v| v.present? }.tap do |h|
        if result['Thumbnail'].present?
          h[:thumbnail] = {
            url: result['Thumbnail']['MediaUrl'],
            contentType: result['Thumbnail']['ContentType'],
            width: result['Thumbnail']['Width'].try(:to_i),
            height: result['Thumbnail']['Height'].try(:to_i),
            size: result['Thumbnail']['FileSize'].try(:to_i)
          }.select{ |k,v| v.present? }
        end
      end
    end

    search
  end

  private

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
    Rails.application.service_config :bingSearch
  end
end
