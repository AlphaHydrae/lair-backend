class AddWarningsCountToMediaScraps < ActiveRecord::Migration
  def change
    add_column :media_scraps, :warnings_count, :integer, null: false, default: 0
  end
end
