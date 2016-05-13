class RenameBookToVolume < ActiveRecord::Migration
  class Item < ActiveRecord::Base; end

  def up
    change_column :items, :type, :string, null: false, limit: 6

    rel = Item.where type: 'Book'
    n = rel.count

    say_with_time "setting type of #{n} volumes" do
      rel.update_all type: 'Volume'
    end

    rel = Event.where("(previous_version->>'type') = ?", 'book').where trackable_type: 'Item'
    n = rel.count

    say_with_time "fixing previous_version of #{n} volume events" do
      rel.select(:id, :previous_version).find_each batch_size: 500 do |event|
        data = event.previous_version
        data['type'] = 'volume'
        Event.where(id: event.id).update_all previous_version: MultiJson.dump(data)
      end
    end
  end

  def down
    rel = Event.where("(previous_version->>'type') = ?", 'volume').where trackable_type: 'Item'
    n = rel.count

    say_with_time "reverting previous_version of #{n} volume events" do
      rel.select(:id, :previous_version).find_each batch_size: 500 do |event|
        data = event.previous_version
        data['type'] = 'book'
        Event.where(id: event.id).update_all previous_version: MultiJson.dump(data)
      end
    end

    rel = Item.where type: 'Volume'
    n = rel.count

    say_with_time "reverting type of #{n} books" do
      rel.update_all type: 'Book'
    end

    change_column :items, :type, :string, null: false, limit: 5
  end
end
