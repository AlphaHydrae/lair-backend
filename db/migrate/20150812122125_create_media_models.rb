class CreateMediaModels < ActiveRecord::Migration
  def up
    create_table :media_sources do |t|
      t.string :api_id, null: false, limit: 12
      t.string :name, null: false, limit: 50
      t.string :normalized_name, null: false, limit: 50
      t.integer :files_count, null: false, default: 0
      t.integer :scans_count, null: false, default: 0
      t.datetime :scanned_at
      t.integer :last_scan_id
      t.timestamps null: false
      t.json :data
      t.json :properties
      t.integer :user_id, null: false
      t.index :api_id, unique: true
      t.index [ :normalized_name, :user_id ], unique: true
      t.foreign_key :users, on_delete: :cascade
    end

    create_table :media_scanners do |t|
      t.string :api_id, null: false, limit: 36
      t.datetime :scanned_at
      t.integer :last_scan_id
      t.timestamps null: false
      t.json :properties
      t.integer :user_id, null: false
      t.index :api_id, unique: true
      t.foreign_key :users, on_delete: :cascade
    end

    create_table :media_files do |t|
      t.string :type, null: false, limit: 14
      t.string :api_id, null: false, limit: 12
      t.text :path, null: false
      t.boolean :deleted, null: false, default: false
      t.integer :source_id, null: false
      t.integer :directory_id
      t.integer :depth, null: false, default: 0
      t.integer :bytesize, limit: 8
      t.integer :files_count, null: false, default: 0
      t.datetime :scanned_at
      t.integer :last_scan_id
      t.datetime :file_created_at
      t.datetime :file_modified_at
      t.datetime :deleted_at
      t.timestamps null: false
      t.json :properties
      t.index :api_id, unique: true
      t.index [ :path, :source_id ], unique: true
      t.foreign_key :media_sources, column: :source_id, on_delete: :cascade
      t.foreign_key :media_files, column: :directory_id, on_delete: :cascade
    end

    create_table :media_scans do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :scanner_id, null: false
      t.integer :files_count, null: false, default: 0
      t.integer :processed_files_count, null: false, default: 0
      t.json :properties
      t.datetime :created_at
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.datetime :processed_at
      t.integer :source_id, null: false
      t.index :api_id, unique: true
      t.foreign_key :media_sources, column: :source_id, on_delete: :cascade
      t.foreign_key :media_scanners, column: :scanner_id, on_delete: :cascade
    end

    create_table :media_scan_files do |t|
      t.integer :scan_id, null: false
      t.text :path, null: false
      t.json :data, null: false
      t.boolean :processed, null: false, default: false
      t.index [ :path, :scan_id ], unique: true
      t.foreign_key :media_scans, column: :scan_id, on_delete: :cascade
    end

    add_foreign_key :media_sources, :media_scans, column: :last_scan_id, on_delete: :nullify
    add_foreign_key :media_scanners, :media_scans, column: :last_scan_id, on_delete: :nullify
    add_foreign_key :media_files, :media_scans, column: :last_scan_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :media_files, :last_scan
    remove_foreign_key :media_scanners, :last_scan
    remove_foreign_key :media_sources, :last_scan
    drop_table :media_scan_files
    drop_table :media_scans
    drop_table :media_files
    drop_table :media_scanners
    drop_table :media_sources
  end
end
