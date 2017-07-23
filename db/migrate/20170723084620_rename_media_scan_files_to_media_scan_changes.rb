class RenameMediaScanFilesToMediaScanChanges < ActiveRecord::Migration
  def up
    rename_table :media_scan_files, :media_scan_changes
    rename_column :media_scans, :processed_files_count, :processed_changes_count
  end

  def down
    rename_column :media_scans, :processed_changes_count, :processed_files_count
    rename_table :media_scan_changes, :media_scan_files
  end
end
