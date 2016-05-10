class CreateScrapsAndMediaUrls < ActiveRecord::Migration
  def change
    create_table :media_urls do |t|
      t.string :api_id, null: false, limit: 12
      t.string :provider, null: false, limit: 20
      t.string :category, null: false, limit: 20
      t.string :provider_id, null: false, limit: 100
      t.integer :creator_id, null: false
      t.timestamps null: false
      t.index %i(provider provider_id), unique: true
      t.foreign_key :users, column: :creator_id, on_delete: :restrict
    end

    create_table :media_scraps do |t|
      t.string :api_id, null: false, limit: 12
      t.string :provider, null: false, limit: 20
      t.string :state, null: false, limit: 20
      t.json :data
      t.text :contents
      t.string :content_type, limit: 50
      t.integer :media_url_id, null: false
      t.integer :creator_id, null: false
      t.datetime :scraping_at
      t.datetime :scraping_canceled_at
      t.datetime :scraping_failed_at
      t.datetime :scraped_at
      t.datetime :expansion_failed_at
      t.datetime :expanded_at
      t.text :error_message
      t.text :error_backtrace
      t.timestamps null: false
      t.index :api_id, unique: true
      t.index :media_url_id, unique: true
      t.foreign_key :media_urls, on_delete: :cascade
      t.foreign_key :users, column: :creator_id, on_delete: :restrict
    end

    add_column :media_files, :state, :string, limit: 20
    add_column :media_files, :extension, :string, limit: 20
    add_column :media_files, :media_url_id, :integer
    add_foreign_key :media_files, :media_urls, on_delete: :nullify

    add_column :works, :media_scrap_id, :integer
    add_column :works, :media_url_id, :integer
    add_index :works, :media_url_id, unique: true
    add_foreign_key :works, :media_scraps, on_delete: :nullify
    add_foreign_key :works, :media_urls, on_delete: :nullify

    add_column :items, :media_scrap_id, :integer
    add_column :items, :media_url_id, :integer
    add_foreign_key :items, :media_scraps, on_delete: :nullify
    add_foreign_key :items, :media_urls, on_delete: :nullify
  end
end
