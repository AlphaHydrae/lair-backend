class AddMediaUrlToOwnerships < ActiveRecord::Migration
  def change
    add_column :ownerships, :media_url_id, :integer
    add_foreign_key :ownerships, :media_urls, on_delete: :nullify
    add_column :media_files, :ownership_id, :integer
    add_foreign_key :media_files, :ownerships, on_delete: :nullify
  end
end
