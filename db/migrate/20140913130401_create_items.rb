class CreateItems < ActiveRecord::Migration
  class Item < ActiveRecord::Base; end

  def up
    create_table :users do |t|
      t.string :api_id, null: false, limit: 12
      t.string :email, null: false, limit: 255
      t.integer :sign_in_count, default: 0, null: false
      t.timestamps null: false
    end

    create_table :languages do |t|
      t.string :tag, null: false, limit: 5
    end

    create_table :people do |t|
      t.string :api_id, null: false, limit: 12
      t.string :last_name, limit: 50
      t.string :first_names, limit: 100
      t.string :pseudonym, limit: 50
      t.integer :creator_id, null: false
      t.integer :updater_id, null: false
      t.timestamps null: false
    end

    create_table :items do |t|
      t.string :api_id, null: false, limit: 6
      t.string :category, null: false, limit: 10
      t.integer :number_of_parts
      t.integer :original_title_id
      t.integer :start_year
      t.integer :end_year
      t.integer :language_id, null: false
      t.integer :image_id
      t.integer :main_image_search_id
      t.json :tags
      t.integer :creator_id, null: false
      t.integer :updater_id, null: false
      t.timestamps null: false
    end

    create_table :item_links do |t|
      t.string :url, null: false, limit: 255
      t.integer :item_id, null: false
      t.integer :language_id
    end

    create_table :item_titles do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :item_id, null: false
      t.integer :language_id, null: false
      t.string :contents, null: false, limit: 150
      t.integer :display_position, null: false
    end

    create_table :item_descriptions do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :item_id, null: false
      t.integer :language_id, null: false
      t.text :contents, null: false
    end

    create_table :item_parts do |t|
      t.string :api_id, null: false, limit: 12
      t.string :type, null: false, limit: 5
      t.integer :item_id, null: false
      t.integer :title_id
      t.integer :image_id
      t.integer :main_image_search_id
      t.string :custom_title, limit: 150
      t.integer :custom_title_language_id
      t.string :effective_title, null: false, limit: 200
      t.integer :year
      t.integer :original_year, null: false
      t.integer :range_start
      t.integer :range_end
      t.integer :language_id, null: false
      t.string :edition, limit: 25
      t.integer :version
      t.string :format, limit: 25
      t.integer :length # minutes (video), pages (book)
      t.json :tags

      # books
      t.string :publisher, limit: 50
      t.string :isbn, limit: 13

      t.integer :creator_id, null: false
      t.integer :updater_id, null: false
      t.timestamps null: false
    end

    create_table :item_people do |t|
      t.integer :item_id, null: false
      t.integer :person_id, null: false
      t.string :relationship, null: false, limit: 20
    end

    create_table :ownerships do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :item_part_id, null: false
      t.integer :user_id, null: false
      t.json :tags
      t.datetime :gotten_at, null: false
      t.integer :creator_id, null: false
      t.integer :updater_id, null: false
      t.timestamps null: false
    end

    create_table :image_searches do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :imageable_id
      t.string :imageable_type, limit: 25
      t.string :engine, null: false, limit: 25
      t.string :query, null: false, limit: 255
      t.json :results, null: false
      t.integer :results_count, null: false
      t.integer :creator_id, null: false
      t.timestamps null: false
    end

    create_table :images do |t|
      t.string :api_id, null: false, limit: 12
      t.string :url, null: false, limit: 255
      t.string :content_type, limit: 50
      t.integer :width
      t.integer :height
      t.integer :size
      t.string :thumbnail_url, limit: 255
      t.string :thumbnail_content_type, limit: 50
      t.integer :thumbnail_width
      t.integer :thumbnail_height
      t.integer :thumbnail_size
      t.timestamps null: false
    end

    create_table :events do |t|
      t.string :api_id, null: false, limit: 36
      t.integer :api_version, null: false
      t.string :event_type, null: false, limit: 12
      t.string :event_subject, limit: 50
      t.string :trackable_type, limit: 50
      t.integer :trackable_id
      t.json :previous_version
      t.integer :cause_id
      t.integer :user_id
      t.datetime :created_at, null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :api_id, unique: true
    add_index :languages, :tag, unique: true
    add_index :items, :category
    add_index :items, :api_id, unique: true
    add_index :item_descriptions, :api_id, unique: true
    add_index :item_titles, :api_id, unique: true
    add_index :item_parts, :api_id, unique: true
    add_index :item_parts, :isbn, unique: true
    add_index :item_links, [ :item_id, :url ], unique: true
    add_foreign_key :image_searches, :users, column: :creator_id
    add_foreign_key :items, :languages
    add_foreign_key :items, :images
    add_foreign_key :items, :image_searches, column: :main_image_search_id
    add_foreign_key :items, :item_titles, column: :original_title_id
    add_foreign_key :items, :users, column: :creator_id
    add_foreign_key :items, :users, column: :updater_id
    add_foreign_key :item_links, :items
    add_foreign_key :item_links, :languages
    add_foreign_key :item_titles, :languages
    add_foreign_key :item_titles, :items
    add_foreign_key :item_descriptions, :items
    add_foreign_key :item_parts, :items
    add_foreign_key :item_parts, :item_titles, column: :title_id
    add_foreign_key :item_parts, :languages
    add_foreign_key :item_parts, :languages, column: :custom_title_language_id
    add_foreign_key :item_parts, :images
    add_foreign_key :item_parts, :image_searches, column: :main_image_search_id
    add_foreign_key :item_parts, :users, column: :creator_id
    add_foreign_key :item_parts, :users, column: :updater_id
    add_foreign_key :item_people, :items
    add_foreign_key :item_people, :people
    add_foreign_key :ownerships, :item_parts
    add_foreign_key :ownerships, :users
    add_foreign_key :ownerships, :users, column: :creator_id
    add_foreign_key :ownerships, :users, column: :updater_id
    add_foreign_key :people, :users, column: :creator_id
    add_foreign_key :people, :users, column: :updater_id
    add_foreign_key :events, :events, column: :cause_id
    add_foreign_key :events, :users
  end

  def down
    remove_foreign_key :item_titles, :items
    drop_table :events
    drop_table :ownerships
    drop_table :item_people
    drop_table :item_parts
    drop_table :item_descriptions
    drop_table :item_links
    drop_table :items
    drop_table :images
    drop_table :image_searches
    drop_table :item_titles
    drop_table :people
    drop_table :languages
    drop_table :users
  end
end
