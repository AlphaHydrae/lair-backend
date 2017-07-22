class RemoveChangedFilesCountFromMediaScan < ActiveRecord::Migration
  def up
    remove_column :media_scans, :changed_files_count
  end

  def down
    add_column :media_scans, :changed_files_count, :integer, null: false, default: 0
  end
end
