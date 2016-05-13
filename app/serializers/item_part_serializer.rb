class ItemPartSerializer < ApplicationSerializer
  include SerializerWithImage

  def build json, options = {}
    json.id record.api_id
    json.itemId record.item.api_id
    json.item serialize(record.item, options.slice(:image_from_search)) if options[:with_item]
    json.title do
      json.id record.title.api_id if record.title.present?
      json.text record.effective_title
      json.language record.custom_title.present? ? record.custom_title_language.tag : record.title.language.tag
    end
    json.titleId record.title.api_id if record.title
    json.customTitle record.custom_title if record.custom_title
    json.customTitleLanguage record.custom_title_language.tag if record.custom_title_language
    json.year record.year if record.year
    json.originalYear record.original_year
    json.language record.language.tag
    json.start record.range_start if record.range_start
    json.end record.range_end if record.range_end
    json.edition record.edition if record.edition
    json.version record.version if record.version
    json.format record.format if record.format
    json.length record.length if record.length
    json.tags record.tags

    if policy.user && options[:ownerships]
      json.ownedByMe options[:ownerships].any?{ |o| o.item_part_id == record.id && o.user_id == policy.user.id }
    end

    build_image json, options
  end
end
