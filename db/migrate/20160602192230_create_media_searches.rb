class CreateMediaSearches < ActiveRecord::Migration
  class MediaFile < ActiveRecord::Base; end

  def up
    create_table :media_searches do |t|
      t.string :api_id, null: false, limit: 12
      t.string :query, null: false
      t.string :provider, null: false, limit: 20
      t.json :results, null: false
      t.integer :results_count, null: false
      t.string :selected_url
      t.integer :user_id, null: false
      t.timestamps null: false
    end

    create_table :media_directories_searches, id: false do |t|
      t.integer :media_directory_id, null: false
      t.integer :media_search_id, null: false
      t.foreign_key :media_files, column: :media_directory_id
      t.foreign_key :media_searches
      t.index :media_directory_id, unique: true
    end

    create_table :media_dumps do |t|
      t.string :api_id, null: false, limit: 12
      t.string :provider, null: false, limit: 20
      t.string :category, null: false, limit: 20
      t.text :content, null: false
      t.string :content_type, null: false, limit: 50
      t.datetime :created_at, null: false
    end
  end

  def down
    drop_table :media_dumps
    drop_table :media_directories_searches
    drop_table :media_searches
  end
end
