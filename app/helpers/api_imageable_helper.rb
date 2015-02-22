module ApiImageableHelper
  def set_image! imageable, data
    if data[:id]
      imageable.image = Image.find data[:id].to_i
    else
      imageable.build_image.fill_from_api_data data
    end
  end
end
