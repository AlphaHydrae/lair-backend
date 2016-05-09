class AddSideEffectsCountToEvents < ActiveRecord::Migration
  def change
    add_column :events, :side_effects_count, :integer, null: false, default: 0
  end
end
