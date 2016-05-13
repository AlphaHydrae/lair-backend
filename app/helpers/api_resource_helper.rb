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
end
