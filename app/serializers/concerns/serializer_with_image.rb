module SerializerWithImage
  extend ActiveSupport::Concern

  def build_image json, options = {}
    if record.image.present?
      json.image serialize(record.image)
    elsif options[:image_from_search] && record.last_image_search.present? && record.last_image_search.results?
      json.image serialize(Image.new.fill_from_api_data(record.last_image_search.results.first.with_indifferent_access))
    end
  end
end
