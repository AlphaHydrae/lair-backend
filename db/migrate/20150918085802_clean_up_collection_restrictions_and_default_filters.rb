class CleanUpCollectionRestrictionsAndDefaultFilters < ActiveRecord::Migration
  class Collection < ActiveRecord::Base; end

  def up
    rel = Collection.where "(data->'restrictions'->>'owners') IS NOT NULL"
    n = rel.count

    say_with_time "fixing restrictions of #{n} collections" do
      rel.select(:id, :data).find_each do |collection|
        data = collection.data
        data['restrictions']['ownerIds'] = data['restrictions'].delete 'owners'
        Collection.where(id: collection.id).update_all data: MultiJson.dump(data)
      end
    end
  end

  def down
    rel = Collection.where "(data->'restrictions'->>'ownerIds') IS NOT NULL"
    n = rel.count

    say_with_time "reverting restrictions of #{n} collections" do
      rel.select(:id, :data).find_each do |collection|
        data = collection.data
        data['restrictions']['owners'] = data['restrictions'].delete 'ownerIds'
        Collection.where(id: collection.id).update_all data: MultiJson.dump(data)
      end
    end
  end
end
