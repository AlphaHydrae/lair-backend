class CreateJobErrors < ActiveRecord::Migration
  class JobError < ActiveRecord::Base; end
  class MediaScan < ActiveRecord::Base; end
  class MediaScrap < ActiveRecord::Base; end

  def up
    create_table :job_errors do |t|
      t.string :cause_type, null: false, limit: 50
      t.integer :cause_id, null: false
      t.string :job, null: false, limit: 50
      t.string :queue, null: false, limit: 20
      t.text :error_message, null: false
      t.text :error_backtrace, null: false
      t.datetime :created_at, null: false
    end

    JobError.reset_column_information

    add_column :media_scans, :job_errors_count, :integer, null: false, default: 0

    rel = MediaScan.where 'error_message IS NOT NULL'
    say_with_time "creating job errors for #{rel.count} media scans" do
      rel.find_each do |scan|
        JobError.new(cause_type: 'MediaScan', cause_id: scan.id, job: 'AnalyzeMediaFilesJob', queue: 'low', error_message: scan.error_message, error_backtrace: scan.error_backtrace).save!
      end
    end

    remove_column :media_scans, :error_message
    remove_column :media_scans, :error_backtrace

    add_column :media_scraps, :job_errors_count, :integer, null: false, default: 0

    rel = MediaScrap.where 'error_message IS NOT NULL'
    say_with_time "creating job errors for #{rel.count} media scraps" do
      rel.find_each do |scrap|
        JobError.new(cause_type: 'MediaScrap', cause_id: scrap.id, job: scrap.contents.present? ? 'ExpandScrapJob' : 'ScrapMediaJob', queue: 'low', error_message: scrap.error_message, error_backtrace: scrap.error_backtrace).save!
      end
    end

    remove_column :media_scraps, :error_message
    remove_column :media_scraps, :error_backtrace
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
