class UpdateItemPartValidations < ActiveRecord::Migration
  class ItemPart < ActiveRecord::Base; end

  def up
    remove_column :item_parts, :effective_title
    add_column :item_parts, :sortable_title, :text

    rel = ItemPart.where 'title_id IS NULL'
    count = rel.count

    say_with_time "setting title_id for #{count} parts" do
      rel.includes(:item).to_a.each do |part|
        title_id = part.item.original_title_id
        title_id = part.item.titles[1].id if part.item.titles.length >= 2
        ItemPart.where(id: part.id).update_all title_id: title_id
      end
    end

    count = ItemPart.count
    say_with_time "setting sortable_title for #{count} parts" do
      ItemPart.find_each do |part|
        sortable_range = "#{part.range_start.to_s.rjust(5, '0')}-#{part.range_end.to_s.rjust(5, '0')}"
        title_parts = [ part.title.contents, sortable_range ]
        title_parts << part.custom_title if part.custom_title.present?
        ItemPart.where(id: part.id).update_all sortable_title: title_parts.join(' ').downcase
      end
    end

    change_column :item_parts, :title_id, :integer, null: false
    change_column :item_parts, :sortable_title, :text, null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
