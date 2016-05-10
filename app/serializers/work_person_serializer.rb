class WorkPersonSerializer < ApplicationSerializer
  def build json, options = {}
    json.relation record.relation
    json.details record.details if record.details.present?
    json.personId record.person.api_id
    json.person serialize(record.person) unless policy.app?
  end
end
