class CollectionSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.name record.name
    json.displayName record.display_name
    json.userId record.user.api_id
    json.user serialize(record.user) if options[:with_user]
    json.public record.public_access
    json.featured record.featured

    if record.restrictions.present?
      json.restrictions do
        json.categories record.restrictions['categories'] if record.restrictions['categories'].present?
        json.ownerIds record.restrictions['ownerIds'] if record.restrictions['ownerIds'].present?
      end
    else
      json.restrictions({})
    end

    if record.default_filters.present?
      json.defaultFilters do
        json.search record.default_filters['search'] if record.default_filters['search'].present?
        json.resource record.default_filters['resource'] if record.default_filters['resource'].present?
        json.categories record.default_filters['categories'] if record.default_filters['categories'].present?
        json.ownerIds record.default_filters['ownerIds'] if record.default_filters['ownerIds'].present?
      end
    else
      json.defaultFilters({})
    end

    if policy.app? || options[:with_links]
      json.workIds Work.joins(:collections).where('collections.id = ?', record.id).pluck(:api_id)
      json.itemIds Item.joins(:collections).where('collections.id = ?', record.id).pluck(:api_id)
      json.ownershipIds Ownership.joins(:collections).where('collections.id = ?', record.id).pluck(:api_id)
    end

    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
