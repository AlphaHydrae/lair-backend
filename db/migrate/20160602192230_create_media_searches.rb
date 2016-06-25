class CreateMediaSearches < ActiveRecord::Migration
  class MediaFile < ActiveRecord::Base; end

  def up
    create_table :media_searches do |t|
      t.string :api_id, null: false, limit: 12
      t.string :query, null: false
      t.string :provider, null: false, limit: 20
      t.json :results, null: false
      t.integer :results_count, null: false
      t.integer :selected
      t.integer :user_id, null: false
      t.timestamps null: false
    end
  end

  def down
    drop_table :media_searches
  end
end
