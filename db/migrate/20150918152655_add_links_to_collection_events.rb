class AddLinksToCollectionEvents < ActiveRecord::Migration
  class Event < ActiveRecord::Base; end

  def up
    rel = Event.where('previous_version IS NOT NULL').where trackable_type: 'Collection'
    n = rel.count

    say_with_time "add link IDs to #{n} Collection events" do
      rel.select(:id, :previous_version).find_each do |event|
        previous_version = event.previous_version
        previous_version.merge! 'workIds' => [], 'itemIds' => [], 'ownershipIds' => []

        if previous_version['restrictions'] && previous_version['restrictions']['owners']
          previous_version['restrictions']['ownerIds'] = previous_version['restrictions'].delete 'owners'
        end

        Event.where(id: event.id).update_all previous_version: MultiJson.dump(previous_version)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
