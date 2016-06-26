class MediaDump < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier
  after_create :clear_previous_dumps

  validates :provider, presence: true, inclusion: { in: MediaUrl::PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :category, presence: true, length: { maximum: 20 }
  validates :content, presence: true
  validates :content_type, presence: true, length: { maximum: 50 }

  private

  def clear_previous_dumps
    MediaDump.where(provider: provider, category: category).where('id != ?', id).delete_all
  end
end
