class DownloadableImages < ActiveRecord::Migration
  class Image < ActiveRecord::Base
  end

  def up
    change_table :images do |t|
      t.string :state, limit: 20
      t.string :original_url, limit: 255
      t.string :original_thumbnail_url, limit: 255
      t.text :upload_error
      t.datetime :uploading_at
      t.datetime :uploaded_at
    end

    Image.update_all state: 'created'
    Image.update_all 'original_url = url, original_thumbnail_url = thumbnail_url'

    change_column :images, :state, :string, null: false, limit: 20
  end

  def down
    remove_column :images, :state
    remove_column :images, :uploading_at
    remove_column :images, :uploaded_at
    remove_column :images, :original_url
    remove_column :images, :original_thumbnail_url
    remove_column :images, :upload_error
  end
end
