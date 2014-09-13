class CreateItems < ActiveRecord::Migration
  def up
    create_table :items do |t|
      t.integer :original_title_id
      t.integer :year, null: false
      t.timestamps null: false
    end

    create_table :item_titles do |t|
      t.integer :item_id, null: false
      t.string :contents, null: false
      t.integer :display_position, null: false
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
