module ApiParamsHelper
  def true_flag? name
    !!params[name].to_s.match(/\A(?:1|y|yes|t|true)\Z/i)
  end

  def false_flag? name
    !!params[name].to_s.match(/\A(?:0|n|no|f|false)\Z/i)
  end

  def all_flag? name
    params[name].to_s.match(/\A(?:\*|a|all)\Z/i)
  end

  def include_in_response? name
    params[:include].to_s == name.to_s || (params[:include].kind_of?(Array) && params[:include].include?(name.to_s))
  end
end
