module ApiResourceHelper
  def load_resource rel
    rel = with_serialization_includes rel if respond_to? :with_serialization_includes
    rel.first
  end

  def load_resource! rel
    rel = with_serialization_includes rel if respond_to? :with_serialization_includes
    rel.first!
  end

  def load_resources rel
    rel = with_serialization_includes rel if respond_to? :with_serialization_includes
    rel.to_a
  end

  def resource_name_to_model name, options = {}
    name.to_s.camelize.singularize.constantize
  end

  def model_to_resource_name model
    model.name.underscore.pluralize
  end
end
