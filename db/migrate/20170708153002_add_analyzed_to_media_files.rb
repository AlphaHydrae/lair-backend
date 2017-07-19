class AddAnalyzedToMediaFiles < ActiveRecord::Migration
  class MediaFile < ActiveRecord::Base; end
  class MediaScan < ActiveRecord::Base; end

  def up
    add_column :media_files, :nfo_error, :string, limit: 12
    MediaFile.where(state: 'invalid').update_all nfo_error: 'invalid'
    MediaFile.where(state: 'duplicated').update_all nfo_error: 'duplicate'
    remove_column :media_files, :state

    add_column :media_files, :analyzed, :boolean, null: false, default: false

    media_scans_rel = MediaScan.where state: %w(analyzing analysis_failed retrying_analysis)
    say_with_time "fixing state of #{media_scans_rel.count} media scans" do
      media_scans_rel.update_all state: 'analyzed'
    end

    remove_columns :media_scans, :analyzed_nfo_files_count, :analyzed_media_files_count, :changed_nfo_files_count, :new_media_files_count, :analysis_failed_at, :analyzing_at, :retrying_analysis_at

    # TODO analysis: create job to ensure all files counts correct
    # TODO analysis: clear all MediaFile/MediaUrl links and re-analyze
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
