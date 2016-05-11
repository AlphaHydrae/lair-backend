class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.datetime :created_at, null: false
    end

    create_table :tags_works, id: false do |t|
      t.integer :tag_id, null: false
      t.integer :work_id, null: false
      t.index %i(tag_id work_id), unique: true
      t.foreign_key :tags, on_delete: :cascade
      t.foreign_key :works, on_delete: :cascade
    end
  end
end
