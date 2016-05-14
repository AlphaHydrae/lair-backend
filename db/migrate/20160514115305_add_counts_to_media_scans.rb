class AddCountsToMediaScans < ActiveRecord::Migration
  def up
    add_column :media_scans, :changed_nfo_files_count, :integer, null: false, default: 0
    add_column :media_scans, :analyzed_nfo_files_count, :integer, null: false, default: 0
    add_column :media_scans, :new_media_files_count, :integer, null: false, default: 0
    add_column :media_scans, :analyzed_media_files_count, :integer, null: false, default: 0
    add_column :media_scans, :analysis_failed_at, :datetime
    add_column :media_scans, :analyzed_at, :datetime
    remove_column :media_scraps, :scraping_canceled_at
  end

  def down
    add_column :media_scraps, :scraping_canceled_at, :datetime
    remove_column :media_scans, :analyzed_at
    remove_column :media_scans, :analysis_failed_at
    remove_column :media_scans, :analyzed_media_files_count
    remove_column :media_scans, :new_media_files_count
    remove_column :media_scans, :analyzed_nfo_files_count
    remove_column :media_scans, :changed_nfo_files_count
  end
end
