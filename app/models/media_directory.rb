class MediaDirectory < MediaAbstractFile
  has_many :files, class_name: 'MediaAbstractFile', foreign_key: :directory_id
end
