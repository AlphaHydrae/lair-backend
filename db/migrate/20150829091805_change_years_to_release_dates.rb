class ChangeYearsToReleaseDates < ActiveRecord::Migration
  class ItemPart < ActiveRecord::Base; end

  def up
    add_column :item_parts, :release_date, :date
    add_column :item_parts, :original_release_date, :date
    add_column :item_parts, :release_date_precision, :string, limit: 1
    add_column :item_parts, :original_release_date_precision, :string, limit: 1

    count = ItemPart.count
    say_with_time "setting release dates for #{count} parts" do
      ItemPart.find_each do |part|

        year_present = part.year.present?
        original_year_present = part.original_year.present?

        updates = {}

        if year_present
          updates[:release_date] = Date.new part.year
          updates[:release_date_precision] = 'y'
        end

        if original_year_present
          updates[:original_release_date] = Date.new part.original_year
          updates[:original_release_date_precision] = 'y'
        end

        ItemPart.where(id: part.id).update_all updates if updates.present?

        part.reload

        raise "Date conversion of year #{part.year} failed" if year_present && part.release_date.blank?
        raise "Date conversion of original year #{part.original_year} failed" if original_year_present && part.original_release_date.blank?
      end
    end

    change_column :item_parts, :original_release_date, :date, null: false

    remove_column :item_parts, :year
    remove_column :item_parts, :original_year
  end

  def down
    add_column :item_parts, :year, :integer
    add_column :item_parts, :original_year, :integer

    count = ItemPart.count
    say_with_time "setting years for #{count} parts" do
      ItemPart.find_each do |part|

        release_date_present = part.release_date.present?
        original_release_date_present = part.original_release_date.present?

        updates = {}
        updates[:year] = part.release_date.year if release_date_present
        updates[:original_year] = part.original_release_date.year if original_release_date_present
        ItemPart.where(id: part.id).update_all updates if updates.present?

        part.reload

        raise "Date conversion of release date #{part.release_date} failed" if release_date_present && part.year.blank?
        raise "Date conversion of original release date #{part.original_release_date} failed" if original_release_date_present && part.original_year.blank?
      end
    end

    change_column :item_parts, :original_year, :integer, null: false

    remove_column :item_parts, :release_date
    remove_column :item_parts, :original_release_date
    remove_column :item_parts, :release_date_precision
    remove_column :item_parts, :original_release_date_precision
  end
end
