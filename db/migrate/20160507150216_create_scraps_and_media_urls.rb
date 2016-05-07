class CreateScrapsAndMediaUrls < ActiveRecord::Migration
  def change
    create_table :media_urls do |t|
      t.string :api_id, null: false, limit: 12
      t.string :provider, null: false, limit: 20
      t.string :category, null: false, limit: 20
      t.string :provider_id, null: false, limit: 100
      t.timestamps null: false
      t.index %i(provider provider_id), unique: true
    end

    create_table :scraps do |t|
      t.string :api_id, null: false, limit: 12
      t.string :provider, null: false, limit: 20
      t.string :state, null: false, limit: 20
      t.text :contents
      t.string :content_type, limit: 50
      t.integer :media_url_id, null: false
      t.datetime :scraping_at
      t.datetime :canceled_at
      t.datetime :scraped_at
      t.datetime :failed_at
      t.text :error_message
      t.text :error_backtrace
      t.timestamps null: false
      t.index :api_id, unique: true
      t.index :media_url_id, unique: true
      t.foreign_key :media_urls
    end

    add_column :media_files, :state, :string, limit: 20
    add_column :media_files, :extension, :string, limit: 20
    add_column :media_files, :media_url_id, :integer
    add_foreign_key :media_files, :media_urls
  end
end
