class CreateVideos < ActiveRecord::Migration
  def up
    create_table :companies do |t|
      t.string :api_id, null: false, limit: 12
      t.string :name, null: false, limit: 100
      t.timestamps null: false
      t.integer :creator_id, null: false
      t.integer :updater_id, null: false
      t.index :api_id, unique: true
      t.index :name, unique: true
      t.foreign_key :users, column: :creator_id
      t.foreign_key :users, column: :updater_id
    end

    create_table :item_companies do |t|
      t.integer :company_id, null: false
      t.integer :item_id, null: false
      t.string :relation, null: false, limit: 20
      t.string :details, limit: 255
      t.index [ :company_id, :item_id ], unique: true
      t.foreign_key :companies
      t.foreign_key :items
    end

    create_table :item_parts_audio_languages, id: false do |t|
      t.integer :video_id, null: false
      t.integer :language_id, null: false
      t.index [ :video_id, :language_id ], unique: true, name: :index_audio_languages_on_video_id_and_language_id
      t.foreign_key :item_parts, column: :video_id
      t.foreign_key :languages
    end

    create_table :item_parts_subtitle_languages, id: false do |t|
      t.integer :video_id, null: false
      t.integer :language_id, null: false
      t.index [ :video_id, :language_id ], unique: true, name: :index_subtitle_languages_on_video_id_and_language_id
      t.foreign_key :item_parts, column: :video_id
      t.foreign_key :languages
    end

    add_index :item_people, [ :item_id, :person_id ], unique: true
    rename_column :item_people, :relationship, :relation
    add_column :item_people, :details, :string, limit: 255
  end

  def down
    remove_column :item_people, :details
    rename_column :item_people, :relation, :relationship
    remove_index :item_people, [ :item_id, :person_id ]
    drop_table :item_parts_subtitle_languages
    drop_table :item_parts_audio_languages
    drop_table :item_companies
    drop_table :companies
  end
end
