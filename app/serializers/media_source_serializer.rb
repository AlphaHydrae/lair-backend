class MediaSourceSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.name record.name

    json.userId record.user.api_id
    json.user serialize(record.user, options[:user_options] || {}) if options[:include_user]

    json.filesCount record.files_count
    json.scansCount record.scans_count

    json.scanPaths record.scan_paths.sort.collect &:to_h if options[:with_scan_paths]

    json.properties record.properties

    json.scannedAt record.scanned_at.iso8601(3) if record.scanned_at.present?
    json.createdAt record.created_at.iso8601(3)
    json.updatedAt record.updated_at.iso8601(3)
  end
end
