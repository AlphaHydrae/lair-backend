class MakePersonCreatorMandatory < ActiveRecord::Migration
  def up
    change_column :people, :creator_id, :integer, null: false
    change_column :people, :updater_id, :integer, null: false
  end

  def down
    change_column :people, :creator_id, :integer, null: true
    change_column :people, :updater_id, :integer, null: true
  end
end
