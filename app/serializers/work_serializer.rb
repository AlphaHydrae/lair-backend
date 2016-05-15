class WorkSerializer < ApplicationSerializer
  include SerializerWithImage

  def build json, options = {}
    json.id record.api_id
    json.category record.category
    json.startYear record.start_year if record.start_year
    json.endYear record.end_year if record.end_year
    json.language record.language.tag
    json.numberOfItems record.number_of_items if record.number_of_items
    json.titles record.titles.to_a.sort_by(&:display_position).collect{ |t| serialize t }

    json.genres record.genres.collect(&:name)
    json.tags record.tags.collect(&:name)

    relationships = record.person_relationships.to_a + record.company_relationships.to_a
    json.relationships relationships.collect{ |r| serialize r }

    json.links record.links.to_a.sort_by(&:url).collect{ |l| serialize l }
    json.properties record.properties.dup

    build_image json, options
  end
end
