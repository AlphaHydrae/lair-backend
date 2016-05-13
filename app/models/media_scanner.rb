class MediaScanner < ActiveRecord::Base
  include ResourceWithIdentifier
  include ResourceWithProperties

  before_create{ set_identifier{ SecureRandom.uuid } }

  belongs_to :user
  has_many :scans, class_name: 'MediaScan'

  validates :user, presence: true
end
