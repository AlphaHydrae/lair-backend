class ItemSerializer < ApplicationSerializer
  include SerializerWithImage

  def build json, options = {}
    json.id record.api_id
    json.type record.type.to_s.camelize(:lower)
    json.workId record.work.api_id
    json.work serialize(record.work, options.slice(:image_from_search)) if options[:with_work]
    json.title do
      json.id record.title.api_id if record.title.present?
      json.text record.effective_title
      json.language record.custom_title.present? ? record.custom_title_language.tag : record.title.language.tag
    end
    json.titleId record.title.api_id if record.title
    json.customTitle record.custom_title if record.custom_title
    json.customTitleLanguage record.custom_title_language.tag if record.custom_title_language
    json.releaseDate serialize_date_with_precision(record, :release_date) if record.release_date
    json.originalReleaseDate serialize_date_with_precision(record, :original_release_date)
    json.language record.language.tag
    json.start record.range_start if record.range_start
    json.end record.range_end if record.range_end
    json.edition record.edition if record.edition
    json.format record.format if record.format
    json.length record.length if record.length
    json.properties record.properties.dup

    if policy.user && options[:ownerships]
      json.ownedByMe options[:ownerships].any?{ |o| o.item_id == record.id && o.user_id == policy.user.id }
    end

    build_image json, options
  end

  private

  def serialize_date_with_precision record, attr
    date = record.send attr
    return nil if date.blank?

    case record.send "#{attr}_precision"
    when 'y'
      date.year.to_s
    when 'm'
      "#{date.year}-#{date.month.to_s.rjust(2, '0')}"
    else
      date.iso8601
    end
  end
end
