class ItemLinkSerializer < ApplicationSerializer
  def build json, options = {}
    json.url record.url
    json.language record.language.tag if record.language
  end
end
