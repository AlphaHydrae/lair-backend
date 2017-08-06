class MultipleProviderScrapers < ActiveRecord::Migration
  class MediaScrap < ActiveRecord::Base; end
  class MediaUrl < ActiveRecord::Base; end

  def up
    remove_index :media_scraps, :media_url_id
    add_column :media_scraps, :scraper, :string, limit: 20

    anidb_scraps_rel = MediaScrap.where provider: 'anidb'
    say_with_time "setting :scraper to :anidb for #{anidb_scraps_rel.count} media scraps" do
      anidb_scraps_rel.update_all scraper: 'anidb'
    end

    omdb_scraps_rel = MediaScrap.where provider: 'imdb'
    say_with_time "setting :scraper to :omdb for #{omdb_scraps_rel.count} media scraps" do
      omdb_scraps_rel.update_all scraper: 'omdb'
    end

    change_column :media_scraps, :scraper, :string, null: false, limit: 20

    add_column :media_urls, :last_scrap_id, :integer
    add_foreign_key :media_urls, :media_scraps, column: :last_scrap_id, on_delete: :nullify

    media_urls_rel = MediaUrl
    say_with_time "setting :last_scrap_id for #{media_urls_rel.count} media URLs" do
      media_urls_rel.select(:id).find_each do |media_url|
        last_scrap = MediaScrap.select(:id).where(media_url_id: media_url.id).order('created_at DESC').limit(1).first
        media_url.update_column :last_scrap_id, last_scrap.id if last_scrap
      end
    end
  end

  def down
    remove_column :media_urls, :last_scrap_id
    remove_column :media_scraps, :scraper
    add_index :media_scraps, :media_url_id, unique: true
  end
end
