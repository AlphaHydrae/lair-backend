module EncodingHelper
  def clean_utf8! data
    if data.kind_of? Hash
      data.each do |key,value|
        data[key] = clean_utf8! value
      end

      data
    elsif data.kind_of? Array
      data.each.with_index do |value,i|
        data[i] = clean_utf8! value
      end

      data
    elsif data.kind_of? String
      data.force_encoding 'utf-8'
    else
      data
    end
  end
end
