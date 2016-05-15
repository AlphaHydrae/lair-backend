class MakePersonCreatorMandatory < ActiveRecord::Migration
  class User < ActiveRecord::Base; end
  class Person < ActiveRecord::Base; end

  def up
    say_with_time "setting creators and updaters for people that are missing them" do
      default_user = User.where(name: 'AlphaHydrae').first!
      Person.where('creator_id IS NULL').update_all creator_id: default_user.id
      Person.where('updater_id IS NULL').update_all updater_id: default_user.id
    end

    change_column :people, :creator_id, :integer, null: false
    change_column :people, :updater_id, :integer, null: false
  end

  def down
    change_column :people, :creator_id, :integer, null: true
    change_column :people, :updater_id, :integer, null: true
  end
end
