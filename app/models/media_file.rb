class MediaFile < MediaAbstractFile
  FILE_TYPES = %i(image meta nfo subtitle unknown video)

  include ResourceWithProperties

  before_create :set_extension
  before_update :remove_searches

  belongs_to :media_url
  belongs_to :source, class_name: 'MediaSource'
  belongs_to :last_scan, class_name: 'MediaScan'
  has_and_belongs_to_many :ownerships

  strip_attributes
  validates :bytesize, presence: true, numericality: { only_integer: true, allow_blank: true }
  validates :file_created_at, presence: true
  validates :scanned_at, presence: true

  def url
    properties['url']
  end

  def nfo?
    file_type.to_s == 'nfo'
  end

  def deleted?
    deleted
  end

  def content?
    !%w(nfo meta).include?(file_type.to_s)
  end

  def file_type
    %i(video nfo subtitle meta audio image).find do |type|
      file_type_extensions(type).include? extension.to_s
    end
  end

  def self.file_type_extensions type
    case type.to_s
    when 'video'
      %w(avi divx m4v mkv mp4 ogm rm wmv)
    when 'nfo'
      %w(nfo)
    when 'subtitle'
      %w(ass idx srt ssa sub sup)
    when 'meta'
      %w(yml)
    when 'audio'
      %w(flac mka mp3)
    when 'image'
      %w(gif jpg png)
    end
  end

  def file_type_extensions type
    self.class.file_type_extensions type
  end

  def range
    markers = episode_markers
    return nil if markers.blank?
    numbers = markers.collect{ |marker| marker.sub(/.*x/, '').to_i }
    Range.new numbers.first, numbers.last
  end

  def special?
    episode_markers.any?{ |marker| marker.match /^0x/ }
  end

  def path= path
    super path
    set_extension
    path
  end

  private

  EPISODE_MARKER_REGEXP = /\d+x\d+/

  def episode_markers
    File.basename(path).scan EPISODE_MARKER_REGEXP
  end

  def set_extension
    ext = File.extname(path).sub(/^\./, '')
    self.extension = ext.present? && ext.length <= 20 ? ext.downcase : nil
  end

  def remove_searches
    return unless media_url_id_changed? && media_url_id

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
