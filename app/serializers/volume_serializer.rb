class VolumeSerializer < ItemSerializer
  def build json, options = {}
    super json, options
    json.publisher record.publisher if record.publisher
    json.version record.version if record.version
    json.isbn record.isbn if record.isbn
  end
end
