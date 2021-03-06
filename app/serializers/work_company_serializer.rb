class WorkCompanySerializer < ApplicationSerializer
  def build json, options = {}
    json.relation record.relation
    json.details record.details if record.details.present?
    json.companyId record.company.api_id
    json.company serialize(record.company) unless policy.app?
  end
end
