module BingSearch
  def self.images query, options = {}
    res = HTTParty.get 'https://api.datamarket.azure.com/Bing/Search/Image', query: { '$format' => 'json', 'Query' => URI::encode("'#{query}'") }, headers: { 'Accept' => 'application/json', 'Authorization' => authorization }
    res = JSON.parse res.body

    res['d']['results'].collect do |result|
      {
        imageUrl: result['MediaUrl'],
        thumbnailUrl: result['Thumbnail']['MediaUrl'],
        contentType: result['ContentType'],
        width: result['Width'],
        height: result['Height'],
        size: result['FileSize']
      }
    end
  end

  private

  def self.authorization
    key = Rails.application.secrets.azure_account_key
    encoded = Base64.strict_encode64 "#{key}:#{key}"
    "Basic #{encoded}"
  end
end
