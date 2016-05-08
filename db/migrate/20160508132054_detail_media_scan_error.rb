class DetailMediaScanError < ActiveRecord::Migration
  def up
    add_column :media_scans, :error_message, :string
    rename_column :media_scans, :backtrace, :error_backtrace
  end

  def down
    rename_column :media_scans, :error_backtrace, :backtrace
    remove_column :media_scans, :error_message
  end
end
