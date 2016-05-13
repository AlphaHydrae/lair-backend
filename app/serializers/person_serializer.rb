class PersonSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.lastName record.last_name if record.last_name.present?
    json.firstNames record.first_names if record.first_names.present?
    json.pseudonym record.pseudonym if record.pseudonym.present?
  end
end
