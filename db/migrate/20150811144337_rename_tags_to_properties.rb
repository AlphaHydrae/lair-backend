class RenameTagsToProperties < ActiveRecord::Migration
  def up
    rename_column :items, :tags, :properties
    rename_column :item_parts, :tags, :properties
    rename_column :ownerships, :tags, :properties
  end

  def down
    rename_column :items, :properties, :tags
    rename_column :item_parts, :properties, :tags
    rename_column :ownerships, :properties, :tags
  end
end
