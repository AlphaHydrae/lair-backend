require 'resque/plugins/workers/lock'

class UpdateMediaOwnershipsJob < ApplicationJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue media_url, user: nil, event: nil
    log_queueing "media URL #{media_url.url} and user #{user.try(:api_id) || 'nil'}"

    if user.present?
      enqueue_after_transaction self, media_url.id, user.id, event.try(:id)
    else
      users = User.select(:id).joins(media_sources: :files).where('media_files.media_url_id = ?', media_url.id).group('users.id').to_a.each do |user|
        enqueue_after_transaction self, media_url.id, user.id, event.try(:id)
      end
    end
  end

  def self.lock_workers media_url_id, user_id, event_id
    :media
  end

  def self.perform media_url_id, user_id, event_id

    media_url = MediaUrl.includes(work: :items).find media_url_id
    user = User.find user_id
    event = Event.where(id: event_id).first

    work = media_url.work
    return if work.blank?

    args = {
      media_url: media_url,
      user: user,
      work: work
    }

    if work.category != 'movie'
      raise "Unsupported work category: #{work.category}"
    end

    MediaUrl.transaction do
      Rails.application.with_current_event event do
        update_single_item_ownership **args
      end
    end
  end

  private

  def self.update_single_item_ownership media_url:, user:, work:

    item = work.items.where(media_url_id: media_url.id).first
    ownership = item.ownerships.where(media_url_id: media_url.id, user_id: user.id).first

    files_rel = MediaFile.joins(:source).where 'media_files.media_url_id = ? AND media_sources.user_id = ? AND media_files.deleted = ?', media_url.id, user.id, false

    if ownership.blank?

      files = files_rel.to_a
      gotten_at = files.collect(&:file_created_at).sort.first
      gotten_at ||= files.collect(&:file_modified_at).sort.first
      gotten_at ||= files.collect(&:created_at).sort.first

      ownership = Ownership.new(item: item, user: user, media_url: media_url, creator: user, gotten_at: gotten_at).tap &:save!
    end

    files_rel.update_all ownership_id: ownership.id
  end
end
