class MediaFingerprint < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create{ set_identifier{ SecureRandom.uuid } }

  belongs_to :media_url
  belongs_to :source, class_name: 'MediaSource'

  strip_attributes
  validates :content_bytesize, presence: true, numericality: { only_integer: true, minimum: 0, allow_blank: true }
  validates :content_files_count, presence: true, numericality: { only_integer: true, minimum: 0, allow_blank: true }
  validates :total_bytesize, presence: true, numericality: { only_integer: true, minimum: 0, allow_blank: true }
  validates :total_files_count, presence: true, numericality: { only_integer: true, minimum: 0, allow_blank: true }
end
