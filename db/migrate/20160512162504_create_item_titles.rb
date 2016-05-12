class CreateItemTitles < ActiveRecord::Migration
  class Item < ActiveRecord::Base; end
  class ItemTitle < ActiveRecord::Base; end
  class Event < ActiveRecord::Base; end

  def up
    create_table :item_titles do |t|
      t.string :api_id, null: false, length: 12
      t.string :contents, null: false, length: 150
      t.integer :display_position, null: false
      t.integer :item_id, null: false
      t.integer :language_id, null: false
      t.index %i(contents item_id language_id), unique: true
      t.foreign_key :items, on_delete: :cascade
      t.foreign_key :languages, on_delete: :restrict
    end

    add_column :items, :original_title_id, :integer
    add_foreign_key :items, :item_titles, column: :original_title_id, on_delete: :nullify

    Item.reset_column_information
    ItemTitle.reset_column_information

    existing_ids = Set.new

    rel = Item.where 'custom_title IS NOT NULL'
    say_with_time "creating item titles for #{rel.count} items with custom titles" do
      rel.find_each batch_size: 100 do |item|

        next while existing_ids.include?(api_id = SecureRandom.random_alphanumeric(12))
        existing_ids << api_id

        item_title = ItemTitle.new(api_id: api_id, contents: item.custom_title, display_position: 0, item_id: item.id, language_id: item.custom_title_language_id).tap &:save!

        item.update_column :original_title_id, item_title.id
      end
    end

    rel = Event.where trackable_type: 'Item', event_type: %w(update delete)
    say_with_time "setting item titles of #{rel.count} previously stored events" do
      rel.find_each batch_size: 500 do |event|

        good = event.previous_version['workTitleId'].present?

        if work_title_id = event.previous_version['title'].delete('id')
          good = true
          event.previous_version['workTitleId'] = work_title_id
        end

        if custom_title = event.previous_version.delete('customTitle')
          good = true
          custom_title_language = event.previous_version.delete('customTitleLanguage')
          event.previous_version['titles'] = [
            { text: custom_title, language: custom_title_language }
          ]
        else
          event.previous_version['titles'] = []
        end

        raise "Missing work title ID or custom title: #{event.previous_version.inspect}" unless good

        event.update_column :previous_version, event.previous_version
      end
    end

    remove_column :items, :custom_title
    remove_column :items, :custom_title_language_id

    rename_column :items, :title_id, :work_title_id
  end

  def down
    rename_column :items, :work_title_id, :title_id

    add_column :items, :custom_title, :string, length: 150
    add_column :items, :custom_title_language_id, :integer

    Item.reset_column_information

    rel = Item.where 'original_title_id IS NOT NULL'
    say_with_time "setting custom title for #{rel.count} items" do
      rel.find_each batch_size: 100 do |item|
        item_title = ItemTitle.find item.original_title_id
        item.update_columns custom_title: item_title.contents, custom_title_language_id: item_title.language_id
      end
    end

    add_foreign_key :items, :languages, column: :custom_title_language_id

    remove_column :items, :original_title_id
    drop_table :item_titles
  end
end
