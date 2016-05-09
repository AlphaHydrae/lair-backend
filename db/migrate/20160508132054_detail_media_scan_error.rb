class DetailMediaScanError < ActiveRecord::Migration
  def up
    change_column :media_scans, :state, :string, null: false, limit: 20
    add_column :media_scans, :error_message, :string
    rename_column :media_scans, :backtrace, :error_backtrace
  end

  def down
    rename_column :media_scans, :error_backtrace, :backtrace
    remove_column :media_scans, :error_message
    change_column :media_scans, :state, :string, null: false, limit: 10
  end
end
