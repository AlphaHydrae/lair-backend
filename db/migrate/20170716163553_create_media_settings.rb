class CreateMediaSettings < ActiveRecord::Migration
  def change
    create_table :media_settings do |t|
      t.string :ignores, array: true, default: [ '**/.*' ]
      t.integer :user_id, null: false
      t.timestamps null: false
      t.index :user_id, unique: true
      t.foreign_key :users, on_delete: :cascade
    end
  end
end
