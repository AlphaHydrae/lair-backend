class CreateItems < ActiveRecord::Migration
  class Item < ActiveRecord::Base; end

  def up
    create_table :languages do |t|
      t.string :iso_code, null: false, limit: 5
    end

    create_table :people do |t|
      t.string :last_name
      t.string :first_names
      t.string :pseudonym
    end

    create_table :items do |t|
      t.string :key, null: false, limit: 6
      t.string :category, null: false, limit: 10
      t.integer :number_of_parts
      t.integer :original_title_id
      t.integer :start_year, null: false
      t.integer :end_year, null: false
      t.integer :language_id, null: false
      t.timestamps null: false
    end

    create_table :item_urls do |t|
      t.string :contents, null: false
      t.integer :item_id, null: false
      t.integer :language_id
    end

    create_table :item_titles do |t|
      t.string :key, null: false, limit: 12
      t.integer :item_id, null: false
      t.integer :language_id, null: false
      t.string :contents, null: false
      t.integer :display_position, null: false
    end

    create_table :item_descriptions do |t|
      t.integer :item_id, null: false
      t.integer :language_id, null: false
      t.text :contents, null: false
    end

    create_table :item_parts do |t|
      t.string :key, null: false, limit: 12
      t.string :type, null: false, limit: 5
      t.integer :item_id, null: false
      t.integer :title_id, null: false
      t.integer :range_start
      t.integer :range_end
      t.integer :language_id, null: false
      t.string :edition
      t.string :version
      t.string :format
      t.integer :length # minutes (video), pages (book)

      # books
      t.string :publisher
      t.string :isbn, limit: 13

      t.timestamps null: false
    end

    create_table :item_people do |t|
      t.integer :item_id, null: false
      t.integer :person_id, null: false
      t.string :relationship, null: false, limit: 20
    end

    create_table :ownerships do |t|
      t.string :key, null: false, limit: 12
      t.integer :item_id, null: false
      t.integer :user_id, null: false
      t.datetime :gotten_at, null: false
    end

    add_index :languages, :iso_code, unique: true
    add_index :items, :category
    add_index :items, :key, unique: true
    add_index :item_titles, :key, unique: true
    add_index :item_parts, :key, unique: true
    add_index :item_parts, :isbn, unique: true
    add_index :item_urls, [ :item_id, :contents ], unique: true
    add_foreign_key :items, :languages
    add_foreign_key :items, :item_titles, column: :original_title_id
    add_foreign_key :item_urls, :items
    add_foreign_key :item_urls, :languages
    add_foreign_key :item_titles, :languages
    add_foreign_key :item_titles, :items
    add_foreign_key :item_descriptions, :items
    add_foreign_key :item_parts, :items
    add_foreign_key :item_parts, :item_titles, column: :title_id
    add_foreign_key :item_parts, :languages
    add_foreign_key :item_people, :items
    add_foreign_key :item_people, :people
    add_foreign_key :ownerships, :items
    add_foreign_key :ownerships, :users
  end

  def down
    remove_foreign_key :item_titles, :items
    drop_table :ownerships
    drop_table :item_people
    drop_table :item_parts
    drop_table :item_descriptions
    drop_table :item_urls
    drop_table :items
    drop_table :item_titles
    drop_table :people
    drop_table :languages
  end
end
