class CleanUpImageSearches < ActiveRecord::Migration
  def up
    remove_column :items, :main_image_search_id
    remove_column :item_parts, :main_image_search_id

    say_with_time "delete #{ImageSearch.count} image searches" do
      ImageSearch.delete_all
    end

    rel = Event.where trackable_type: 'ImageSearch'
    say_with_time "delete #{rel.count} image search events" do
      rel.delete_all
    end
  end

  def down
    add_column :items, :main_image_search_id, :integer
    add_column :item_parts, :main_image_search_id, :integer
    add_foreign_key :items, :image_searches, column: :main_image_search_id
    add_foreign_key :item_parts, :image_searches, column: :main_image_search_id
  end
end
