class FixScrapedItemTypes < ActiveRecord::Migration
  def up
    change_column :items, :original_release_date, :date, null: true
  end

  def down
    change_column :items, :original_release_date, :date, null: false
  end
end
