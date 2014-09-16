class CreateItems < ActiveRecord::Migration
  def up
    create_table :items do |t|
      # TODO: add type (book/movie)
      # TODO: add serial boolean (single vs. series)
      # TODO: add category/tags
      # TODO: add url(s)
      # TODO: add description with language
      t.integer :original_title_id
      t.integer :year, null: false
      t.string :language, null: false, limit: 5
      t.timestamps null: false
    end

    create_table :item_titles do |t|
      t.integer :item_id, null: false
      t.string :contents, null: false
      t.integer :display_position, null: false
    end

    create_table :books do |t|
      # TODO: add link to item
      # TODO: add link to item title
      # TODO: add description with language
      t.integer :volume_start
      t.integer :volume_end
      t.string :language, null: false, limit: 5
      t.string :edition
      t.string :edition_number
      t.string :publisher
      t.string :format
      t.integer :pages
      t.string :isbn10, limit: 10
      t.string :isbn13, limit: 13
      t.timestamps null: false
    end

    add_foreign_key :item_titles, :items
    add_foreign_key :items, :item_titles, column: :original_title_id
    add_index :item_titles, [ :item_id, :display_position ], unique: true
  end

  def down
    remove_foreign_key :item_titles, :items
    drop_table :items
    drop_table :item_titles
  end
end
