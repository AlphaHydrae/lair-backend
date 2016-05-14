class FixItemTitleLength < ActiveRecord::Migration
  def up
    change_column :item_titles, :api_id, :string, null: false, limit: 12
    change_column :item_titles, :contents, :string, null: false, limit: 500
  end

  def down
    change_column :item_titles, :contents, :string, null: false
    change_column :item_titles, :api_id, :string, null: false
  end
end
