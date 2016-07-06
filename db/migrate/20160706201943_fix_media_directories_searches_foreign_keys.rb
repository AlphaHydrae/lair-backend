class FixMediaDirectoriesSearchesForeignKeys < ActiveRecord::Migration
  def change
    remove_foreign_key :media_directories_searches, :media_directory
    remove_foreign_key :media_directories_searches, :media_searches
    add_foreign_key :media_directories_searches, :media_files, column: :media_directory_id, on_delete: :cascade
    add_foreign_key :media_directories_searches, :media_searches, on_delete: :cascade
  end
end
