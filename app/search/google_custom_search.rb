require 'google/api_client'

module GoogleCustomSearch
  def self.images! search
    search.engine = :googleCustomSearch
    search.check_rate_limit!
    return search if search.rate_limit.exceeded?

    client = Google::APIClient.new authorization: nil, application_name: 'lair', application_version: Rails.application.version
    custom_search = client.discovered_api 'customsearch'

    res = client.execute(api_method: custom_search.cse.list, parameters: {
      'q' => search.query,
      'num' => 10,
      'searchType' => 'image',
      'cx' => config[:search_engine_id],
      'key' => public_api_key
    })

    # TODO: use custom exception
    raise "Image search failed with status code #{res.status}: #{res.body}" unless res.status == 200

    res = JSON.parse res.body

    search.results = res['items'].collect do |item|
      {
        url: item['link'],
        contentType: item['mime'],
        width: item['image']['width'],
        height: item['image']['height'],
        size: item['image']['byteSize']
      }.select{ |k,v| v.present? }.tap do |h|
        image = item['image']
        if image['thumbnailLink']
          h[:thumbnail] = {
            url: image['thumbnailLink'],
            width: image['thumbnailWidth'],
            height: image['thumbnailHeight']
          }.select{ |k,v| v.present? }
        end
      end
    end

    search
  end

  private

  def self.parse_image data
    { url: data['src'] }.tap do |h|
      h[:width] = data['width'].to_i if data['width']
      h[:height] = data['height'].to_i if data['height']
    end
  end

  def self.public_api_key
    Rails.application.secrets.google_public_api_key
  end

  def self.config
    Rails.application.service_config :googleCustomSearch
  end
end
