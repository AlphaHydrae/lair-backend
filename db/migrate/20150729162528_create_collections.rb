class CreateCollections < ActiveRecord::Migration
  class User < ActiveRecord::Base
  end

  def up
    change_table :users do |t|
      t.string :name, limit: 25
      t.string :normalized_name, limit: 25
      t.boolean :active, null: false, default: false
      t.integer :roles_mask, null: false, default: 0
    end

    User.all.each do |u|
      u.name = u.email.sub(/@.*$/, '').gsub(/\./, '-')
      u.normalized_name = u.name.downcase
      u.save!
    end

    change_column :users, :name, :string, null: false, limit: 25
    change_column :users, :normalized_name, :string, null: false, limit: 25
    add_index :users, :normalized_name, unique: true

    create_table :collections do |t|
      t.string :api_id, null: false, limit: 12
      t.string :name, null: false, limit: 50
      t.string :normalized_name, null: false, limit: 50
      t.string :display_name, null: false, limit: 50
      t.boolean :public_access, null: false, default: false
      t.boolean :featured, null: false, default: false
      t.json :data, null: false
      t.integer :linked_items_count, null: false, default: 0
      t.integer :linked_parts_count, null: false, default: 0
      t.integer :linked_ownerships_count, null: false, default: 0
      t.integer :user_id, null: false
      t.integer :creator_id, null: false
      t.integer :updater_id, null: false
      t.timestamps null: false
      t.index :api_id, unique: true
      t.index [ :normalized_name, :user_id ], unique: true
      t.foreign_key :users
    end

    create_table :collection_items do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :collection_id, null: false
      t.integer :item_id, null: false
      t.timestamps null: false
      t.index :api_id, unique: true
      t.index [ :collection_id, :item_id ], unique: true
      t.foreign_key :collections
      t.foreign_key :items
    end

    create_table :collection_parts do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :collection_id, null: false
      t.integer :part_id, null: false
      t.timestamps null: false
      t.index :api_id, unique: true
      t.index [ :collection_id, :part_id ], unique: true
      t.foreign_key :collections
      t.foreign_key :item_parts, column: :part_id
    end

    create_table :collection_ownerships do |t|
      t.string :api_id, null: false, limit: 12
      t.integer :collection_id, null: false
      t.integer :ownership_id, null: false
      t.timestamps null: false
      t.index :api_id, unique: true
      t.index [ :collection_id, :ownership_id ], unique: true
      t.foreign_key :collections
      t.foreign_key :ownerships
    end

    create_table :collections_users, id: false do |t|
      t.integer :collection_id, null: false
      t.integer :user_id, null: false
      t.index [ :collection_id, :user_id ], unique: true
      t.foreign_key :collections
      t.foreign_key :users
    end
  end

  def down
    remove_column :users, :name
    remove_column :users, :normalized_name
    remove_column :users, :active
    remove_column :users, :roles_mask
    drop_table :collection_items
    drop_table :collection_parts
    drop_table :collection_ownerships
    drop_table :collections_users
    drop_table :collections
  end
end
