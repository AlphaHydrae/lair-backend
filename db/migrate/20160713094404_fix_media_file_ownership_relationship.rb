class FixMediaFileOwnershipRelationship < ActiveRecord::Migration
  def up
    create_table :media_files_ownerships, id: false do |t|
      t.integer :media_file_id, null: false
      t.integer :ownership_id, null: false
      t.index %i(media_file_id ownership_id), unique: true
      t.foreign_key :media_files, on_delete: :cascade
      t.foreign_key :ownerships, on_delete: :cascade
    end

    remove_column :media_files, :ownership_id
  end

  def down
    add_column :media_files, :ownership_id, :integer
    add_foreign_key :media_files, :ownerships, on_delete: :nullify

    drop_table :media_files_ownerships
  end
end
