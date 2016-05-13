class RenameItemsAndParts < ActiveRecord::Migration
  class Event < ActiveRecord::Base; end
  class ImageSearch < ActiveRecord::Base; end

  def up
    remove_foreign_key :collection_items, :collection
    remove_foreign_key :collection_items, :item
    remove_index :collection_items, :api_id
    remove_index :collection_items, [ :collection_id, :item_id ]
    remove_foreign_key :collection_parts, :collection
    remove_foreign_key :collection_parts, :part
    remove_index :collection_parts, :api_id
    remove_index :collection_parts, [ :collection_id, :part_id ]
    remove_foreign_key :item_companies, :company
    remove_foreign_key :item_companies, :item
    remove_index :item_companies, [ :company_id, :item_id ]
    remove_foreign_key :item_descriptions, :item
    remove_index :item_descriptions, :api_id
    remove_foreign_key :item_links, :item
    remove_index :item_links, [ :item_id, :url ]
    remove_foreign_key :item_parts, :item
    remove_index :item_parts, :api_id
    remove_index :item_parts, :isbn
    remove_foreign_key :item_people, :item
    remove_index :item_people, [ :item_id, :person_id ]
    remove_foreign_key :item_titles, :item
    remove_index :item_titles, :api_id
    remove_foreign_key :items, :image
    remove_foreign_key :items, :language
    remove_foreign_key :items, :original_title
    remove_foreign_key :items, :last_image_search
    remove_foreign_key :items, :creator
    remove_foreign_key :items, :updater
    remove_index :items, :api_id
    remove_index :items, :category
    remove_foreign_key :ownerships, :item_part

    rename_table :collection_items, :collection_works
    rename_column :collection_works, :item_id, :work_id
    rename_table :collection_parts, :collection_items
    rename_column :collection_items, :part_id, :item_id
    rename_column :collections, :linked_items_count, :linked_works_count
    rename_column :collections, :linked_parts_count, :linked_items_count
    rename_table :items, :works
    rename_column :works, :number_of_parts, :number_of_items
    rename_table :item_companies, :work_companies
    rename_column :work_companies, :item_id, :work_id
    rename_table :item_descriptions, :work_descriptions
    rename_column :work_descriptions, :item_id, :work_id
    rename_table :item_links, :work_links
    rename_column :work_links, :item_id, :work_id
    rename_table :item_parts, :items
    rename_column :items, :item_id, :work_id
    rename_table :item_parts_audio_languages, :items_audio_languages
    rename_table :item_parts_subtitle_languages, :items_subtitle_languages
    rename_table :item_people, :work_people
    rename_column :work_people, :item_id, :work_id
    rename_table :item_titles, :work_titles
    rename_column :work_titles, :item_id, :work_id
    rename_column :ownerships, :item_part_id, :item_id

    Event.where(trackable_type: 'Item').update_all trackable_type: 'Work'
    Event.where(trackable_type: 'ItemPart').update_all trackable_type: 'Item'

    rel = Event.where("previous_version IS NOT NULL AND (previous_version->>'numberOfParts') IS NOT NULL").where trackable_type: 'Work'
    n = rel.count

    say_with_time "fixing previous_version for #{n} Work events" do
      rel.select(:id, :previous_version).find_each batch_size: 500 do |event|
        updated = event.previous_version
        updated['numberOfItems'] = updated.delete 'numberOfParts'
        Event.where(id: event.id).update_all previous_version: MultiJson.dump(updated)
      end
    end

    rel = Event.where('previous_version IS NOT NULL').where trackable_type: 'Item'
    n = rel.count

    say_with_time "fixing previous_version for #{n} Item events" do
      rel.select(:id, :previous_version).find_each batch_size: 500 do |event|
        updated = event.previous_version
        updated['workId'] = updated.delete 'itemId'
        Event.where(id: event.id).update_all previous_version: MultiJson.dump(updated)
      end
    end

    rel = Event.where('previous_version IS NOT NULL').where trackable_type: 'Ownership'
    n = rel.count

    say_with_time "fixing previous_version for #{n} Ownership events" do
      rel.select(:id, :previous_version).find_each batch_size: 500 do |event|
        updated = event.previous_version
        updated['itemId'] = updated.delete 'partId'
        Event.where(id: event.id).update_all previous_version: MultiJson.dump(updated)
      end
    end

    n = ImageSearch.count
    say_with_time "fixing imageable_type of #{n} image searches" do
      ImageSearch.where(imageable_type: 'Item').update_all imageable_type: 'Work'
      ImageSearch.where(imageable_type: 'ItemPart').update_all imageable_type: 'Item'
    end

    add_foreign_key :collection_works, :collections, on_delete: :cascade
    add_foreign_key :collection_works, :works, on_delete: :cascade
    add_index :collection_works, :api_id, unique: true
    add_index :collection_works, [ :collection_id, :work_id ], unique: true
    add_foreign_key :collection_items, :collections, on_delete: :cascade
    add_foreign_key :collection_items, :items, on_delete: :cascade
    add_index :collection_items, :api_id, unique: true
    add_index :collection_items, [ :collection_id, :item_id ], unique: true
    add_foreign_key :work_companies, :companies, on_delete: :cascade
    add_foreign_key :work_companies, :works, on_delete: :cascade
    add_index :work_companies, [ :work_id, :company_id ], unique: true
    add_foreign_key :work_descriptions, :works, on_delete: :cascade
    add_index :work_descriptions, :api_id, unique: true
    add_foreign_key :work_links, :works, on_delete: :cascade
    add_index :work_links, [ :work_id, :url ], unique: true
    add_foreign_key :items, :works, on_delete: :cascade
    add_index :items, :api_id, unique: true
    add_index :items, :isbn, unique: true
    add_foreign_key :work_people, :works, on_delete: :cascade
    add_index :work_people, [ :work_id, :person_id ], unique: true
    add_foreign_key :work_titles, :works
    add_index :work_titles, :api_id, unique: true
    add_foreign_key :works, :images, on_delete: :nullify
    add_foreign_key :works, :languages, on_delete: :restrict
    add_foreign_key :works, :work_titles, column: :original_title_id, on_delete: :nullify
    add_foreign_key :works, :image_searches, column: :last_image_search_id, on_delete: :nullify
    add_foreign_key :works, :users, column: :creator_id, on_delete: :restrict
    add_foreign_key :works, :users, column: :updater_id, on_delete: :restrict
    add_index :works, :api_id, unique: true
    add_index :works, :category
    add_foreign_key :ownerships, :items, on_delete: :cascade
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
