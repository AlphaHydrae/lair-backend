class AddActiveAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :active_at, :datetime
  end
end
