require 'resque/plugins/workers/lock'

class UpdateMediaOwnershipsJob < ApplicationJob
  extend Resque::Plugins::Workers::Lock

  @queue = :low

  def self.enqueue media_url:, user: nil, event: nil
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

    MediaUrl.transaction do
      Rails.application.with_current_event event do
        if work.category == 'movie'
          update_single_item_ownership **args
        elsif work.category == 'anime'
          update_items_ownership **args
        else
          raise "Unsupported work category: #{work.category}"
        end
      end
    end
  end

  private

  def self.update_items_ownership media_url:, user:, work:

    items = work.items.where(media_url_id: media_url.id).to_a
    ownerships = Ownership.joins(:item).where('items.id IN (?) AND ownerships.user_id = ? AND ownerships.owned = ? AND ownerships.media_url_id = ?', items.collect(&:id), user.id, true, media_url.id).to_a
    files = MediaFile.joins(:source).where('media_files.media_url_id = ? AND media_sources.user_id = ? AND media_files.deleted = ?', media_url.id, user.id, false).to_a

    main_items = items.reject &:special?

    ownerships_files = {}
    remaining_files = files

    items.each do |item|

      ownership = ownerships.find{ |o| o.item_id == item.id }

      range = item.range
      matching_files = if range
        files.select{ |f| f.special? == item.special? && f.range.try(:include?, range) }
      elsif main_items.length == 1 && item == main_items.first
        files.reject &:special?
      elsif items.length == 1
        files
      end

      if matching_files.present?
        if ownership.blank?
          ownership = create_ownership item: item, user: user, media_url: media_url, files: matching_files
        end

        ownerships_files[ownership] ||= []
        ownerships_files[ownership] += matching_files

        remaining_files -= matching_files
      elsif ownership.present? && ownership.owned
        ownership.media_files.clear
        ownership.yielded_at = Time.now

        ownership.cache_previous_version
        ownership.updater = user

        ownership.save!
      end
    end

    ownerships_files.each do |ownership,files|
      ownership.media_files = files
    end

    remaining_files.each{ |f| f.ownerships.clear }
  end

  def self.update_single_item_ownership media_url:, user:, work:

    item = work.items.where(media_url_id: media_url.id).first
    ownership = item.ownerships.where(media_url_id: media_url.id, user_id: user.id).first

    files = MediaFile.joins(:source).where('media_files.media_url_id = ? AND media_sources.user_id = ? AND media_files.deleted = ?', media_url.id, user.id, false).to_a

    if ownership.blank?
      ownership = create_ownership item: item, user: user, media_url: media_url, files: files
    end

    ownership.media_files = files
  end

  def self.create_ownership item:, user:, media_url:, files:

    gotten_at = files.collect(&:file_created_at).sort.first
    gotten_at ||= files.collect(&:file_modified_at).sort.first
    gotten_at ||= files.collect(&:created_at).sort.first

    Ownership.new(item: item, user: user, media_url: media_url, creator: user, gotten_at: gotten_at).tap &:save!
  end
end
