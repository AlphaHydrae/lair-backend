class AddChangeToMediaScanFiles < ActiveRecord::Migration
  def change
    add_column :media_scan_files, :change_type, :string, null: false, limit: 10
  end
end
