class FixForeignKeys < ActiveRecord::Migration
  def up
    remove_foreign_key :companies, :updater
    add_foreign_key :companies, :users, column: :creator_id, on_delete: :restrict
    add_foreign_key :companies, :users, column: :updater_id, on_delete: :restrict

    remove_foreign_key :collections, :user
    add_foreign_key :collections, :users, on_delete: :restrict
    add_foreign_key :collections, :users, column: :creator_id, on_delete: :restrict
    add_foreign_key :collections, :users, column: :updater_id, on_delete: :restrict

    remove_foreign_key :collections_users, :collection
    remove_foreign_key :collections_users, :user
    add_foreign_key :collections_users, :collections, on_delete: :cascade
    add_foreign_key :collections_users, :users, on_delete: :restrict

    remove_foreign_key :ownerships, :item_part
    remove_foreign_key :ownerships, :user
    remove_foreign_key :ownerships, :creator
    remove_foreign_key :ownerships, :updater
    add_foreign_key :ownerships, :item_parts, on_delete: :cascade
    add_foreign_key :ownerships, :users, on_delete: :restrict
    add_foreign_key :ownerships, :users, column: :creator_id, on_delete: :restrict
    add_foreign_key :ownerships, :users, column: :updater_id, on_delete: :restrict

    remove_foreign_key :collection_ownerships, :collection
    remove_foreign_key :collection_ownerships, :ownership
    add_foreign_key :collection_ownerships, :collections, on_delete: :cascade
    add_foreign_key :collection_ownerships, :ownerships, on_delete: :cascade

    remove_foreign_key :item_parts, :image
    remove_foreign_key :item_parts, :item
    remove_foreign_key :item_parts, :language
    remove_foreign_key :item_parts, :title
    remove_foreign_key :item_parts, :custom_title_language
    remove_foreign_key :item_parts, :creator
    remove_foreign_key :item_parts, :updater
    add_foreign_key :item_parts, :images, on_delete: :nullify
    add_foreign_key :item_parts, :items, on_delete: :cascade
    add_foreign_key :item_parts, :languages, on_delete: :restrict
    change_column :item_parts, :title_id, :integer, null: true
    add_foreign_key :item_parts, :item_titles, column: :title_id, on_delete: :nullify
    add_foreign_key :item_parts, :languages, column: :custom_title_language_id, on_delete: :restrict
    add_foreign_key :item_parts, :users, column: :creator_id, on_delete: :restrict
    add_foreign_key :item_parts, :users, column: :updater_id, on_delete: :restrict

    remove_foreign_key :item_parts_audio_languages, :video
    remove_foreign_key :item_parts_audio_languages, :language
    add_foreign_key :item_parts_audio_languages, :item_parts, column: :video_id, on_delete: :cascade
    add_foreign_key :item_parts_audio_languages, :languages, on_delete: :restrict

    remove_foreign_key :item_parts_subtitle_languages, :video
    remove_foreign_key :item_parts_subtitle_languages, :language
    add_foreign_key :item_parts_subtitle_languages, :item_parts, column: :video_id, on_delete: :cascade
    add_foreign_key :item_parts_subtitle_languages, :languages, on_delete: :restrict

    remove_foreign_key :collection_parts, :collection
    remove_foreign_key :collection_parts, :part
    add_foreign_key :collection_parts, :collections, on_delete: :cascade
    add_foreign_key :collection_parts, :item_parts, column: :part_id, on_delete: :cascade

    remove_foreign_key :items, :image
    remove_foreign_key :items, :language
    remove_foreign_key :items, :original_title
    remove_foreign_key :items, :creator
    remove_foreign_key :items, :updater
    add_foreign_key :items, :images, on_delete: :nullify
    add_foreign_key :items, :languages, on_delete: :restrict
    add_foreign_key :items, :item_titles, column: :original_title_id, on_delete: :nullify
    add_foreign_key :items, :users, column: :creator_id, on_delete: :restrict
    add_foreign_key :items, :users, column: :updater_id, on_delete: :restrict

    remove_foreign_key :collection_items, :collection
    remove_foreign_key :collection_items, :item
    add_foreign_key :collection_items, :collections, on_delete: :cascade
    add_foreign_key :collection_items, :items, on_delete: :cascade

    remove_foreign_key :item_companies, :company
    remove_foreign_key :item_companies, :item
    add_foreign_key :item_companies, :companies, on_delete: :cascade
    add_foreign_key :item_companies, :items, on_delete: :cascade

    remove_foreign_key :item_descriptions, :item
    add_foreign_key :item_descriptions, :items, on_delete: :cascade
    add_foreign_key :item_descriptions, :languages, on_delete: :restrict

    remove_foreign_key :item_links, :item
    remove_foreign_key :item_links, :language
    add_foreign_key :item_links, :items, on_delete: :cascade
    add_foreign_key :item_links, :languages, on_delete: :restrict

    remove_foreign_key :item_people, :item
    remove_foreign_key :item_people, :person
    add_foreign_key :item_people, :items, on_delete: :cascade
    add_foreign_key :item_people, :people, on_delete: :restrict

    remove_foreign_key :item_titles, :item
    remove_foreign_key :item_titles, :language
    add_foreign_key :item_titles, :items, on_delete: :cascade
    add_foreign_key :item_titles, :languages, on_delete: :restrict

    remove_foreign_key :events, :user
    remove_foreign_key :events, :cause
    add_foreign_key :events, :users, on_delete: :restrict
    add_foreign_key :events, :events, column: :cause_id, on_delete: :cascade

    remove_foreign_key :image_searches, :creator
    rename_column :image_searches, :creator_id, :user_id
    add_foreign_key :image_searches, :users, on_delete: :restrict

    remove_foreign_key :people, :creator
    remove_foreign_key :people, :updater
    add_foreign_key :people, :users, column: :creator_id, on_delete: :restrict
    add_foreign_key :people, :users, column: :updater_id, on_delete: :restrict
  end

  def down
    remove_foreign_key :companies, :creator
    remove_foreign_key :companies, :updater
    add_foreign_key :companies, :users, column: :updater_id

    remove_foreign_key :collections, :user
    remove_foreign_key :collections, :creator
    remove_foreign_key :collections, :updater
    add_foreign_key :collections, :users

    remove_foreign_key :collections_users, :collection
    remove_foreign_key :collections_users, :user
    add_foreign_key :collections_users, :collections
    add_foreign_key :collections_users, :users

    remove_foreign_key :ownerships, :item_part
    remove_foreign_key :ownerships, :user
    remove_foreign_key :ownerships, :creator
    remove_foreign_key :ownerships, :updater
    add_foreign_key :ownerships, :item_parts
    add_foreign_key :ownerships, :users
    add_foreign_key :ownerships, :users, column: :creator_id
    add_foreign_key :ownerships, :users, column: :updater_id

    remove_foreign_key :collection_ownerships, :collection
    remove_foreign_key :collection_ownerships, :ownership
    add_foreign_key :collection_ownerships, :collections
    add_foreign_key :collection_ownerships, :ownerships

    remove_foreign_key :item_parts, :image
    remove_foreign_key :item_parts, :item
    remove_foreign_key :item_parts, :language
    remove_foreign_key :item_parts, :title
    remove_foreign_key :item_parts, :custom_title_language
    remove_foreign_key :item_parts, :creator
    remove_foreign_key :item_parts, :updater
    add_foreign_key :item_parts, :images
    add_foreign_key :item_parts, :items
    add_foreign_key :item_parts, :languages
    change_column :item_parts, :title_id, :integer, null: false
    add_foreign_key :item_parts, :item_titles, column: :title_id
    add_foreign_key :item_parts, :languages, column: :custom_title_language_id
    add_foreign_key :item_parts, :users, column: :creator_id
    add_foreign_key :item_parts, :users, column: :updater_id

    remove_foreign_key :item_parts_audio_languages, :video
    remove_foreign_key :item_parts_audio_languages, :language
    add_foreign_key :item_parts_audio_languages, :item_parts, column: :video_id
    add_foreign_key :item_parts_audio_languages, :languages

    remove_foreign_key :item_parts_subtitle_languages, :video
    remove_foreign_key :item_parts_subtitle_languages, :language
    add_foreign_key :item_parts_subtitle_languages, :item_parts, column: :video_id
    add_foreign_key :item_parts_subtitle_languages, :languages

    remove_foreign_key :collection_parts, :collection
    remove_foreign_key :collection_parts, :part
    add_foreign_key :collection_parts, :collections
    add_foreign_key :collection_parts, :item_parts, column: :part_id

    remove_foreign_key :items, :image
    remove_foreign_key :items, :language
    remove_foreign_key :items, :original_title
    remove_foreign_key :items, :creator
    remove_foreign_key :items, :updater
    add_foreign_key :items, :images
    add_foreign_key :items, :languages
    add_foreign_key :items, :item_titles, column: :original_title_id
    add_foreign_key :items, :users, column: :creator_id
    add_foreign_key :items, :users, column: :updater_id

    remove_foreign_key :collection_items, :collection
    remove_foreign_key :collection_items, :item
    add_foreign_key :collection_items, :collections
    add_foreign_key :collection_items, :items

    remove_foreign_key :item_companies, :company
    remove_foreign_key :item_companies, :item
    add_foreign_key :item_companies, :companies
    add_foreign_key :item_companies, :items

    remove_foreign_key :item_descriptions, :item
    remove_foreign_key :item_descriptions, :languages
    add_foreign_key :item_descriptions, :items

    remove_foreign_key :item_links, :item
    remove_foreign_key :item_links, :language
    add_foreign_key :item_links, :items
    add_foreign_key :item_links, :languages

    remove_foreign_key :item_people, :item
    remove_foreign_key :item_people, :person
    add_foreign_key :item_people, :items
    add_foreign_key :item_people, :people

    remove_foreign_key :item_titles, :item
    remove_foreign_key :item_titles, :language
    add_foreign_key :item_titles, :items
    add_foreign_key :item_titles, :languages

    remove_foreign_key :events, :user
    remove_foreign_key :events, :cause
    add_foreign_key :events, :users
    add_foreign_key :events, :events, column: :cause_id

    remove_foreign_key :image_searches, :user
    rename_column :image_searches, :user_id, :creator_id
    add_foreign_key :image_searches, :users, column: :creator_id

    remove_foreign_key :people, :creator
    remove_foreign_key :people, :updater
    add_foreign_key :people, :users, column: :creator_id
    add_foreign_key :people, :users, column: :updater_id
  end
end
