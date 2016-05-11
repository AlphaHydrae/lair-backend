class AddSpecialToItems < ActiveRecord::Migration
  def change
    add_column :items, :special, :boolean, null: false, default: false
  end
end
