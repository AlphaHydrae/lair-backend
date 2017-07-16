class RenameChangedScanFileChangeToModified < ActiveRecord::Migration
  class MediaScanFile < ActiveRecord::Base; end

  def up
    rel = MediaScanFile.where change_type: 'changed'
    say_with_time %/changing "changed" to "modified" for #{rel.count} media scan files/ do
      rel.update_all change_type: 'modified'
    end
  end

  def down
    rel = MediaScanFile.where change_type: 'modified'
    say_with_time %/changing "modified" to "changed" for #{rel.count} media scan files/ do
      rel.update_all change_type: 'changed'
    end
  end
end
