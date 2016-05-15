class AddStates < ActiveRecord::Migration
  class MediaScrap < ActiveRecord::Base; end

  def change
    add_column :media_scans, :scanning_at, :datetime
    add_column :media_scans, :processing_at, :datetime
    add_column :media_scans, :retrying_processing_at, :datetime
    add_column :media_scans, :analyzing_at, :datetime
    add_column :media_scans, :retrying_analysis_at, :datetime
    rename_column :media_scans, :failed_at, :processing_failed_at

    say_with_time "fixing states and dates #{MediaScan.count} media scans" do
      MediaScan.where(state: 'failed').update_all state: 'processing_failed'
      MediaScan.update_all 'scanning_at = created_at, processing_at = scanned_at, analyzing_at = processed_at'
    end

    add_column :media_scraps, :expanding_at, :datetime
    add_column :media_scraps, :retrying_scraping_at, :datetime
    add_column :media_scraps, :retrying_expansion_at, :datetime

    say_with_time "setting expanding_at for #{MediaScrap.count} media scraps" do
      MediaScrap.update_all 'expanding_at = scraped_at'
    end
  end
end
