module ResourceWithProperties
  extend ActiveSupport::Concern

  included do
    before_save :clean_properties
  end

  def properties
    if p = read_attribute(:properties)
      p
    else
      write_attribute :properties, {}
      read_attribute :properties
    end
  end

  def set_properties_from_params params
    return if params.nil?

    props = self.properties

    params.each_pair do |k,v|
      if v.nil?
        props.delete k.to_s
      elsif v.kind_of?(String) || v.kind_of?(Numeric) || v == !!v
        props[k.to_s] = v
      elsif v.kind_of? Array
        props[k.to_s] = v.collect &:to_s
      end
    end

    props.delete_if{ |k,v| !params.key?(k) }

    self.properties = props
    self.properties
  end

  def clean_properties
    self.properties.delete_if{ |k,v| v.nil? }
    write_attribute :properties, nil if read_attribute(:properties).blank?
    true
  end
end
