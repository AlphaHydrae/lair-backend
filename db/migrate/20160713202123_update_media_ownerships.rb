class UpdateMediaOwnerships < ActiveRecord::Migration

  def up

    i = 0
    n = MediaUrl.count

    users_with_media_sources = User.joins(:media_sources).to_a

    media_url_ids_by_user = users_with_media_sources.inject({}) do |memo,user|
      memo[user] = Set.new
      memo
    end

    users_with_media_sources.each do |user|
      MediaScan.joins(:source).where('media_sources.user_id = ?', user.id).order('created_at DESC').find_each do |media_scan|

        media_urls_rel = MediaUrl.joins(:files).group('media_urls.id').where 'media_files.last_scan_id = ?', media_scan.id
        media_urls_rel = media_urls_rel.where 'media_urls.id NOT IN (?)', media_url_ids_by_user[user] if media_url_ids_by_user[user].present?
        media_urls = media_urls_rel.to_a

        if media_urls.present?
          say_with_time "queueing update media ownerships jobs for #{media_urls.length} media urls" do
            media_urls.each do |media_url|
              UpdateMediaOwnershipsJob.enqueue media_url: media_url, user: user, event: media_scan.last_scan_event
            end
          end
        end

        media_url_ids_by_user[user] += media_urls.collect(&:id)
      end
    end

    remaining_media_urls = MediaUrl.where 'id NOT IN (?)', media_url_ids_by_user.inject(Set.new){ |memo,(user,ids)| memo += ids }.to_a
    raise "Unexpected remaining media urls: #{remaining_media_urls.inspect}" if remaining_media_urls.any?
  end

  def down
    # nothing to do
  end
end
