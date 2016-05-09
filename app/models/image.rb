class Image < ActiveRecord::Base
  include SimpleStates
  include ResourceWithIdentifier

  after_commit :upload_image, on: :create

  states :created, :uploading, :uploaded, :upload_failed
  event :start_upload, from: :created, to: :uploading
  event :finish_upload, from: :uploading, to: :uploaded
  event :fail_upload, from: :uploading, to: :upload_failed
  event :retry_upload, from: :upload_failed, to: :created

  before_create :set_identifier

  has_many :works
  has_many :items

  scope :linked, ->{ joins('LEFT OUTER JOIN works ON images.id = works.image_id').joins('LEFT OUTER JOIN items ON images.id = items.image_id').where('works.id IS NOT NULL OR items.id IS NOT NULL') }
  scope :orphaned, ->{ joins('LEFT OUTER JOIN works ON images.id = works.image_id').joins('LEFT OUTER JOIN items ON images.id = items.image_id').where('works.id IS NULL AND items.id IS NULL') }

  validates :state, inclusion: { in: %w(created uploading uploaded upload_failed) }
  validates :url, presence: true, length: { maximum: 255 }
  validates :content_type, absence: { unless: :url }, length: { maximum: 50 }
  validates :width, absence: { unless: :url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :height, absence: { unless: :url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :size, absence: { unless: :url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :thumbnail_url, length: { maximum: 255 }
  validates :thumbnail_content_type, absence: { unless: :thumbnail_url }, length: { maximum: 50 }
  validates :thumbnail_width, absence: { unless: :thumbnail_url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :thumbnail_height, absence: { unless: :thumbnail_url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }
  validates :thumbnail_size, absence: { unless: :thumbnail_url }, numericality: { only_integer: true, minimum: 1, allow_blank: true }

  def fill_from_api_data data
    %i(url contentType width height size).each{ |attr| send "#{attr.to_s.underscore}=", data[attr] if data.key? attr }
    %i(url contentType width height size).each{ |attr| send "thumbnail_#{attr.to_s.underscore}=", data[:thumbnail][attr] if data[:thumbnail].key?(attr) } if data[:thumbnail].kind_of?(Hash) && data[:thumbnail].key?(:url)
    self
  end

  private

  def upload_image
    UploadImageJob.enqueue self
  end
end
