class AddLastImageSearchToItemsAndParts < ActiveRecord::Migration
  def up
    add_column :items, :last_image_search_id, :integer
    add_foreign_key :items, :image_searches, column: :last_image_search_id, on_delete: :nullify
    add_column :item_parts, :last_image_search_id, :integer
    add_foreign_key :item_parts, :image_searches, column: :last_image_search_id, on_delete: :nullify
  end

  def down
    remove_column :items, :last_image_search_id
    remove_column :item_parts, :last_image_search_id
  end
end
