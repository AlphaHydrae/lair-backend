class MediaScannerSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.userId record.user.api_id
    json.scannedAt record.scanned_at.iso8601(3) if record.scanned_at.present?
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
    json.properties record.properties
  end
end
