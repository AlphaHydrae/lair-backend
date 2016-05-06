class MediaScanSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.state record.state
    json.changedFilesCount record.changed_files_count

    if record.scanned? || record.processed?
      json.filesCount record.files_count
    elsif record.scanned?
      json.scannedAt record.scanned_at.iso8601(3)
    elsif record.processed?
      json.processedAt record.processed_at.iso8601(3)
    elsif record.canceled?
      json.canceledAt record.canceled_at.iso8601(3)
    end

    json.createdAt record.created_at.iso8601(3)
  end
end
