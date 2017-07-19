class AddChangesCountsToMediaScans < ActiveRecord::Migration
  CHANGE_TYPES = %i(added modified deleted)

  class MediaScan < ActiveRecord::Base; end
  class MediaScanFile < ActiveRecord::Base; end

  def up
    add_column :media_scans, :added_files_count, :integer, null: false, default: 0
    add_column :media_scans, :modified_files_count, :integer, null: false, default: 0
    add_column :media_scans, :deleted_files_count, :integer, null: false, default: 0

    counts = say_with_time "counting change types for #{MediaScanFile.count} media scan files" do
      MediaScanFile.select(:scan_id, :change_type, 'count(id) as change_type_count').group(:scan_id, :change_type).to_a
    end

    counts_by_scan_id = counts.inject({}) do |memo, c|
      raise "Unknown change type #{c.change_type}" unless CHANGE_TYPES.include? c.change_type.to_sym
      memo[c.scan_id] ||= {}
      memo[c.scan_id]["#{c.change_type}_files_count".to_sym] = c.change_type_count
      memo
    end

    say_with_time "updating changes counts for #{counts_by_scan_id.keys.length} media scans" do
      counts_by_scan_id.each do |scan_id,counts|
        MediaScan.where(id: scan_id).update_all counts
      end
    end
  end

  def down
    remove_column :media_scans, :added_files_count
    remove_column :media_scans, :modified_files_count
    remove_column :media_scans, :deleted_files_count
  end
end
