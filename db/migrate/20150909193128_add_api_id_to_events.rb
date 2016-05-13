class AddApiIdToEvents < ActiveRecord::Migration
  def up
    add_column :events, :trackable_api_id, :string, limit: 12
    add_index :events, [ :trackable_type, :trackable_id ]
    add_index :events, [ :trackable_type, :trackable_api_id ]

    i = 0
    count = Event.count

    Event.select(:id, :trackable_type, :trackable_id).includes(:trackable).find_in_batches batch_size: 1250 do |events|
      percentage = ((i + events.length) * 100 / count.to_f).round(1)
      say_with_time "set api_id of events #{i + 1}-#{i + events.length} (#{percentage}%)" do
        events.each do |event|
          Event.where(id: event.id).update_all trackable_api_id: event.trackable.api_id
        end
      end

      i += events.length
    end

    change_column :events, :trackable_api_id, :string, null: false, limit: 12
  end

  def down
    remove_index :events, [ :trackable_type, :trackable_id ]
    remove_column :events, :trackable_api_id
  end
end
