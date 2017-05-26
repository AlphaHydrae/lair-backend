class UserSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.name record.name

    json.email record.email if policy.show_email?
    json.emailMd5 Digest::MD5.hexdigest(record.email)

    if policy.show_active?
      json.active record.active
      json.activeAt record.active_at if record.active_at
    end

    json.roles record.roles.collect(&:to_s).collect{ |role| role.camelize :lower }
    json.createdAt record.created_at.iso8601(3)
  end
end
