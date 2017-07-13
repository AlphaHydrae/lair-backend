class AddAnalyzedToMediaFiles < ActiveRecord::Migration
  class MediaFile < ActiveRecord::Base; end
  class MediaScan < ActiveRecord::Base; end

  def up
    add_column :media_files, :nfo_error, :string, limit: 12
    MediaFile.where(state: 'invalid').update_all nfo_error: 'invalid'
    MediaFile.where(state: 'duplicated').update_all nfo_error: 'duplicate' # TODO analysis: ensure no occurrences of "duplicated"
    remove_column :media_files, :state

    add_column :media_files, :analyzed, :boolean, null: false, default: false

    # TODO analysis: log
    MediaScan.where(state: %w(analyzing analysis_failed retrying_analysis)).update_all state: 'processed'
    remove_columns :media_scans, :analyzed_nfo_files_count, :analyzed_media_files_count, :changed_nfo_files_count, :new_media_files_count, :analysis_failed_at, :analyzing_at, :retrying_analysis_at

    # TODO analysis: create job to ensure all files counts correct
    # TODO analysis: clear all MediaFile/MediaUrl links and re-analyze
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
