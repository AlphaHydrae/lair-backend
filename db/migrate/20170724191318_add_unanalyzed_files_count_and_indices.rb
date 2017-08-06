class AddUnanalyzedFilesCountAndIndices < ActiveRecord::Migration
  BATCH_SIZE = 250

  class MediaAbstractFile < ActiveRecord::Base
    self.table_name = 'media_files'
    belongs_to :directory, class_name: 'MediaAbstractFile'
  end

  class MediaFile < MediaAbstractFile
    class << self
      def sti_name
        'MediaFile'
      end
    end
  end

  class MediaDirectory < MediaAbstractFile
    class << self
      def sti_name
        'MediaDirectory'
      end
    end

    has_many :files, class_name: 'MediaAbstractFile', foreign_key: :directory_id
  end

  def up
    add_column :media_files, :unanalyzed_files_count, :integer, null: false, default: 0
    add_index :media_files, :extension
    add_index :media_files, :path
    add_index :media_files, :type

    say_with_time "mark all deleted files as analyzed" do
      MediaFile.where(deleted: true).update_all analyzed: true
    end

    children_unanalyzed_files_count_by_directory = Hash.new do |hash,key|
      hash[key] = 0
    end

    rel = MediaDirectory.where deleted: false
    max_depth = rel.maximum :depth

    while max_depth >= 0
      directories_rel = rel.where depth: max_depth
      say_with_time "setting unanalyzed_files_count for #{directories_rel.count} directories at depth #{max_depth}" do
        directories_rel.select(:id, :directory_id, :path).find_in_batches batch_size: BATCH_SIZE do |directories|
          unanalyzed_files_counts = MediaFile.select(:directory_id, 'COUNT(id) AS computed_unanalyzed_files_count').where(directory_id: directories.collect(&:id), analyzed: false).group(:directory_id).having('COUNT(id) >= 1').to_a
          directories.each do |directory|
            count = unanalyzed_files_counts.find{ |c| c.directory_id == directory.id }

            actual_count = (count.try(:computed_unanalyzed_files_count) || 0) + children_unanalyzed_files_count_by_directory[directory.id]
            children_unanalyzed_files_count_by_directory.delete directory.id

            MediaDirectory.where(id: directory.id).update_all unanalyzed_files_count: actual_count if actual_count >= 1

            if max_depth >= 1
              children_unanalyzed_files_count_by_directory[directory.directory_id] += actual_count
            end
          end
        end
      end

      max_depth -= 1
    end
  end

  def down
    remove_index :media_files, :type
    remove_index :media_files, :path
    remove_index :media_files, :extension
    remove_column :media_files, :unanalyzed_files_count
  end
end
