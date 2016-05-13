class ItemPersonSerializer < ApplicationSerializer
  def build json, options = {}
    json.relation record.relationship
    json.personId record.person.api_id
    json.person serialize(record.person)
  end
end
