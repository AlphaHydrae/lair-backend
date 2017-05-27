class MediaScanFileSerializer < ApplicationSerializer
  def build json, options = {}
    json.path record.path
    json.scanId record.scan.api_id
    json.data record.data if options[:include_data]
    json.processed record.processed
    json.changeType record.change_type
  end
end
