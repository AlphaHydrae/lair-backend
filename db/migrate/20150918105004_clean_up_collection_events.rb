class CleanUpCollectionEvents < ActiveRecord::Migration
  class Event < ActiveRecord::Base; end

  def up
    rel = Event.where('previous_version IS NOT NULL').where trackable_type: 'Collection'
    n = rel.count

    say_with_time "fixing previous_version of #{n} Collection events" do
      rel.select(:id, :previous_version).find_each do |event|
        previous_version = event.previous_version
        previous_version.delete 'user'
        Event.where(id: event.id).update_all previous_version: MultiJson.dump(previous_version)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
