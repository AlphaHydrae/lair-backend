class CreateMediaFingerprints < ActiveRecord::Migration
  def change
    create_table :media_fingerprints do |t|
      t.string :api_id, null: false, limit: 36
      t.index :api_id, unique: true

      t.integer :content_files_count, null: false, default: 0
      t.integer :content_bytesize, null: false, default: 0, limit: 8
      t.integer :total_files_count, null: false, default: 0
      t.integer :total_bytesize, null: false, default: 0, limit: 8

      t.integer :source_id, null: false
      t.integer :media_url_id, null: false
      t.index %i(source_id media_url_id), unique: true
      t.foreign_key :media_sources, column: :source_id, on_delete: :cascade
      t.foreign_key :media_urls, on_delete: :cascade

      t.timestamps null: false
    end
  end
end
