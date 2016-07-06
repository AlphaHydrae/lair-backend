class MediaFile < MediaAbstractFile
  FILE_TYPES = %i(image meta nfo subtitle unknown video)

  include SimpleStates
  include ResourceWithProperties

  before_create :set_extension
  before_update :remove_searches

  states :created, :unlinked, :changed, :deleted, :invalid, :duplicated, :linked
  event :mark_as_created, to: :created
  event :mark_as_unlinked, to: :unlinked
  event :mark_as_changed, to: :changed
  event :mark_as_deleted, to: :deleted
  event :mark_as_invalid, to: :invalid
  event :mark_as_duplicated, to: :duplicated
  event :mark_as_linked, to: :linked

  belongs_to :media_url
  belongs_to :source, class_name: 'MediaSource'
  belongs_to :last_scan, class_name: 'MediaScan'

  strip_attributes
  validates :bytesize, presence: true, numericality: { only_integer: true, allow_blank: true }
  validates :file_created_at, presence: true
  validates :scanned_at, presence: true

  def url
    properties['url']
  end

  def nfo?
    file_type == 'nfo'
  end

  def deleted?
    deleted
  end

  def file_type
    case extension.to_s
    when 'nfo'
      'nfo'
    when 'yml'
      'meta'
    when 'gif', 'jpg', 'png'
      'image'
    when 'avi', 'divx', 'mkv', 'mp4', 'ogm', 'rm'
      'video'
    when 'idx', 'srt', 'ssa', 'sub'
      'subtitle'
    else
      'unknown'
    end
  end

  def path= path
    super path
    set_extension
    path
  end

  private

  def set_extension
    ext = File.extname(path).sub(/^\./, '')
    self.extension = ext.present? && ext.length <= 20 ? ext.downcase : nil
  end

  def remove_searches
    return unless state_changed? && state.to_s == 'linked'

    affected_directories = directory.with_child_files do |rel|
      rel = rel.where 'media_files.type = ?', MediaDirectory.name
    end.select :id

    MediaSearch.joins(:directories).where('media_files.id IN (?)', affected_directories.collect(&:id)).includes(:directories).find_each do |search|
      if search.directories.length == 1
        search.destroy
        Rails.logger.info "Deleted search #{search.api_id} due to linking of NFO file #{api_id}"
      else
        search.directories -= directory
      end
    end
  end
end
