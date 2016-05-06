class AddStateToMediaScans < ActiveRecord::Migration
  def up
    add_column :media_scans, :state, :string, null: false, limit: 10
    add_column :media_scans, :canceled_at, :datetime
    add_column :media_scans, :scanned_at, :datetime
    add_column :media_scans, :failed_at, :datetime
    add_column :media_scans, :backtrace, :text
    add_column :media_scans, :changed_files_count, :integer, null: false, default: 0
    remove_column :media_scans, :started_at
    remove_column :media_scans, :ended_at
  end

  def down
    add_column :media_scans, :ended_at, :datetime
    add_column :media_scans, :started_at, :datetime, null: false
    remove_column :media_scans, :changed_files_count
    remove_column :media_scans, :backtrace
    remove_column :media_scans, :failed_at
    remove_column :media_scans, :scanned_at
    remove_column :media_scans, :canceled_at
    remove_column :media_scans, :state
  end
end
