class CreateGenres < ActiveRecord::Migration
  def change
    create_table :genres do |t|
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.datetime :created_at, null: false
    end

    create_table :genres_works, id: false do |t|
      t.integer :genre_id, null: false
      t.integer :work_id, null: false
      t.index %i(genre_id work_id), unique: true
      t.foreign_key :genres, on_delete: :cascade
      t.foreign_key :works, on_delete: :cascade
    end
  end
end
