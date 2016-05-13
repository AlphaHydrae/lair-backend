class FillInItemStartAndEndYears < ActiveRecord::Migration
  def up
    i = 0
    count = Item.count

    Item.select(:id, :start_year, :end_year).find_in_batches batch_size: 250 do |items|
      percentage = ((i + items.length) * 100 / count.to_f).round 1
      say_with_time "fill in start_year and end_year for items #{i + 1}-#{i + items.length} (#{percentage}%)" do
        items.each do |item|

          rel = ItemPart.select(:original_release_date).where(item_id: item.id).limit(1)
          first_part = rel.order('original_release_date ASC').first
          next if first_part.blank?
          last_part = rel.order('original_release_date DESC').first

          updates = {}
          updates[:start_year] = first_part.original_release_date.year if item.start_year.blank? || first_part.original_release_date.year < item.start_year
          updates[:end_year] = last_part.original_release_date.year if item.end_year.blank? || last_part.original_release_date.year < item.end_year

          Item.where(id: item.id).update_all updates if updates.present?
        end
      end

      i += items.length
    end
  end

  def down
  end
end
