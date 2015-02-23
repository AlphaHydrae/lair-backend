module ApiImageableHelper
  def set_image! imageable, data
    if data[:id]
      imageable.image = Image.where(api_id: data[:id].to_s).first!
    else
      imageable.build_image.fill_from_api_data data
    end
  end
end
