class MultipleProviderScrapers < ActiveRecord::Migration
  class MediaScrap < ActiveRecord::Base; end

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
  end

  def down
    remove_column :media_scraps, :scraper
    add_index :media_scraps, :media_url_id, unique: true
  end
end
