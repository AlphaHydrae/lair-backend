class AddImmediateNfoFilesCountToMediaDirectory < ActiveRecord::Migration
  class MediaAbstractFile < ActiveRecord::Base
    self.table_name = 'media_files'
    belongs_to :directory, class_name: 'MediaAbstractFile'
  end

  class MediaDirectory < MediaAbstractFile
    class << self
      def sti_name
        'MediaDirectory'
      end
    end

    has_many :files, class_name: 'MediaAbstractFile', foreign_key: :directory_id
  end

  class MediaFile < MediaAbstractFile
    class << self
      def sti_name
        'MediaFile'
      end
    end
  end

  def up
    add_column :media_files, :immediate_nfo_files_count, :integer, null: false, default: 0

    n = MediaDirectory.count
    results = say_with_time "counting immediate NFO files count for #{n} directories" do
      MediaDirectory.select('media_files.id', 'count(files_media_files.id) as immediate_nfo_files_count_value').joins(:files).where('files_media_files.extension = ?', 'nfo').group('media_files.id').to_a
    end

    say_with_time "setting immediate NFO files count for #{n} directores" do
      results.each do |result|
        MediaDirectory.where(id: result.id).update_all immediate_nfo_files_count: result.immediate_nfo_files_count_value
      end
    end
  end

  def down
    remove_column :media_files, :immediate_nfo_files_count
  end
end
