class AddYieldedAtToOwnerships < ActiveRecord::Migration
  class Ownership < ActiveRecord::Base; end

  def up
    add_column :ownerships, :owned, :boolean, null: false, default: true
    add_column :ownerships, :yielded_at, :datetime
    Ownership.update_all owned: true
  end

  def down
    remove_column :ownerships, :yielded_at
    remove_column :ownerships, :owned
  end
end
