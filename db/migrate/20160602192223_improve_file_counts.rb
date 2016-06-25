class ImproveFileCounts < ActiveRecord::Migration
  class MediaFile < ActiveRecord::Base; end

  def up
    add_column :media_files, :nfo_files_count, :integer, null: false, default: 0
    add_column :media_files, :linked_files_count, :integer, null: false, default: 0

    counts_by_directory_id = {}

    max_depth = MediaFile.where(type: 'MediaDirectory', deleted: false).maximum 'depth'
    (0..max_depth).each do |depth|

      depth = 2 - depth

      dirs_rel = MediaFile.where type: 'MediaDirectory', depth: depth, deleted: false
      n = dirs_rel.count
      i = 0
      batch_size = 250

      dirs_rel.find_in_batches batch_size: batch_size do |dirs|
        say_with_time "setting file counts for directories at depth #{depth} (#{i + 1}-#{i + dirs.length} / #{n})" do
          dirs.each do |dir|

            files_count = MediaFile.where(type: 'MediaFile', depth: depth + 1, directory_id: dir.id, deleted: false).count
            nfo_files_count = MediaFile.where(type: 'MediaFile', depth: depth + 1, directory_id: dir.id, deleted: false, extension: 'nfo').count
            linked_files_count = MediaFile.where(type: 'MediaFile', depth: depth + 1, directory_id: dir.id, deleted: false, state: 'linked').count

            files_count += (counts_by_directory_id[dir.id].try(:[], :files_count) || 0)
            nfo_files_count += (counts_by_directory_id[dir.id].try(:[], :nfo_files_count) || 0)
            linked_files_count += (counts_by_directory_id[dir.id].try(:[], :linked_files_count) || 0)

            dir.update_columns files_count: files_count, nfo_files_count: nfo_files_count, linked_files_count: linked_files_count

            if dir.directory_id
              counts_by_directory_id[dir.directory_id] ||= { files_count: 0, nfo_files_count: 0, linked_files_count: 0 }
              counts_by_directory_id[dir.directory_id][:files_count] += files_count
              counts_by_directory_id[dir.directory_id][:nfo_files_count] += nfo_files_count
              counts_by_directory_id[dir.directory_id][:linked_files_count] += linked_files_count
            end
          end

          i += dirs.length
        end
      end
    end
  end

  def down
    remove_column :media_files, :linked_files_count
    remove_column :media_files, :nfo_files_count

    dirs_rel = MediaFile
      .where(type: 'MediaDirectory')

    n = dirs_rel.count

    dirs_rel = dirs_rel
      .select('media_files.*, count(child_files.id) AS tmp_files_count')
      .joins('LEFT OUTER JOIN media_files AS child_files ON media_files.id = child_files.directory_id')
      .group('media_files.id')

    say_with_time "settings files_count for #{n} directories" do
      dirs_rel.find_each do |dir|
        dir.update_columns files_count: dir.tmp_files_count
      end
    end
  end
end
