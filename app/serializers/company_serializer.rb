class CompanySerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.name record.name
  end
end
