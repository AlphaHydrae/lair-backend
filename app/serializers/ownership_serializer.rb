class OwnershipSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.partId record.item_part.api_id
    json.userId record.user.api_id
    json.tags record.tags
    json.gottenAt record.gotten_at.iso8601(3)
    json.yieldedAt record.yielded_at.iso8601(3) if record.yielded_at

    json.part serialize(record.item_part, options.slice(:ownerships)) if options[:with_part]
    json.user serialize(record.user) if options[:with_user]

    # TODO: add createdAt/updatedAt
  end
end
