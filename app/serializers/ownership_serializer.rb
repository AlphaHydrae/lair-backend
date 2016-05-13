class OwnershipSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.itemId record.item.api_id
    json.userId record.user.api_id
    json.properties record.properties.dup
    json.gottenAt record.gotten_at.iso8601(3)
    json.yieldedAt record.yielded_at.iso8601(3) if record.yielded_at

    json.item serialize(record.item, options.slice(:ownerships)) if options[:with_item]
    json.user serialize(record.user) if options[:with_user]

    # TODO: add createdAt/updatedAt
  end
end
