class ItemSerializer < ApplicationSerializer
  include SerializerWithImage

  def build json, options = {}
    json.id record.api_id
    json.category record.category
    json.startYear record.start_year
    json.endYear record.end_year
    json.language record.language.tag
    json.numberOfParts record.number_of_parts if record.number_of_parts
    json.titles record.titles.to_a.sort_by(&:display_position).collect{ |t| serialize t }
    json.relationships record.relationships.to_a.collect{ |r| serialize r }
    json.links record.links.to_a.sort_by(&:url).collect{ |l| serialize l }
    json.tags record.tags

    build_image json, options
  end
end
