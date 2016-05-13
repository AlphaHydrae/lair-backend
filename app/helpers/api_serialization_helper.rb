module ApiSerializationHelper
  def serialize records, options = {}

    custom_user = options.delete :current_user
    options.reverse_merge!(respond_to?(:serialization_options) ? serialization_options(records) : {})

    if records.kind_of? Array
      records.collect{ |r| policy_serializer(r, custom_user).serialize(options) }
    else
      policy_serializer(records, custom_user).serialize(options)
    end
  end
end
