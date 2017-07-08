class AddAnalyzedToMediaFiles < ActiveRecord::Migration
  class MediaScan < ActiveRecord::Base; end

  def up
    add_column :media_files, :analyzed, :boolean, null: false, default: false
    MediaScan.where(state: %w(analyzing analysis_failed retrying_analysis)).update_all state: 'analyzed'
    remove_columns :media_scans, :analyzed_nfo_files_count, :analyzed_media_files_count, :analysis_failed_at, :analyzing_at, :retrying_analysis_at
  end

  def down
    add_column :media_scans, :analyzed_nfo_files_count, :integer, null: false, default: 0
    add_column :media_scans, :analyzed_media_files_count, :integer, null: false, default: 0
    add_column :media_scans, :analysis_failed_at, :datetime
    add_column :media_scans, :analyzing_at, :datetime
    add_column :media_scans, :retrying_analysis_at, :datetime
    remove_column :media_files, :analyzed
  end
end
