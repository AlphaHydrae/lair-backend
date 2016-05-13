class CleanUpEventData < ActiveRecord::Migration
  class Event < ActiveRecord::Base; end

  def up
    i = 0
    rel = Event.select(:id, :trackable_type, :previous_version).where('previous_version IS NOT NULL')
    count = rel.count :id

    rel.find_in_batches batch_size: 750 do |events|

      percentage = ((i + events.length) * 100 / count.to_f).round 1
      say_with_time "clean up previous_version of events #{i + 1}-#{i + events.length} (#{percentage}%)" do
        events.each do |event|
          data = event.previous_version

          data['properties'] = data.delete 'tags' if data.key? 'tags'

          if event.trackable_type == 'Item'
            data.delete 'startYear' if data.key?('startYear') && data['startYear'].nil?
            data.delete 'endYear' if data.key?('endYear') && data['endYear'].nil?

            data['relationships'].each do |relationship|
              relationship.delete 'company'
              relationship.delete 'person'
            end
          elsif event.trackable_type == 'ItemPart'
            data['type'] = 'book'
            data['releaseDate'] = data.delete('year').to_s if data.key? 'year'
            data['originalReleaseDate'] = data.delete('originalYear').to_s if data.key? 'originalYear'
          end

          Event.where(id: event.id).update_all previous_version: MultiJson.dump(data)
        end
      end

      i += events.length
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
