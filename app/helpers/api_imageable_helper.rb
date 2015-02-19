module ApiImageableHelper
  def set_image! imageable, data
    if data[:id]
      imageable.image = Image.find data[:id].to_i
    else
      image = imageable.build_image
      %i(url contentType width height size).each{ |attr| image.send "#{attr.to_s.underscore}=", data[attr] if data.key? attr }
      %i(url contentType width height size).each{ |attr| image.send "thumbnail_#{attr.to_s.underscore}=", data[:thumbnail][attr] if data[:thumbnail].key?(attr) } if data[:thumbnail].kind_of?(Hash) && data[:thumbnail].key?(:url)
    end
  end
end
