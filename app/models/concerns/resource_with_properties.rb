module ResourceWithProperties
  extend ActiveSupport::Concern

  include EncodingHelper

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
    return unless params.kind_of? Hash
    self.properties = merge_properties self.properties, params
  end

  def clean_properties
    clean_utf8! self.properties
    self.properties.delete_if{ |k,v| v.nil? }
    write_attribute :properties, nil if read_attribute(:properties).blank?
    true
  end

  private

  def merge_properties props1, props2
    if props1.kind_of?(Hash) && props2.kind_of?(Hash)
      props2.each do |k,v|
        if v.nil?
          props1.delete k
        else
          props1[k] = merge_properties props1[k], props2[k]
        end
      end

      props1
    else
      props2
    end
  end
end
