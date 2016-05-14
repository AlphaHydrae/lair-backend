class MediaScanSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.state record.state.to_s.camelize(:lower)

    json.sourceId record.source.api_id
    json.source serialize(record.source, options[:source_options] || {}) if options[:include_source]

    json.changedFilesCount record.changed_files_count

    if record.files_count.present?
      json.filesCount record.files_count
      json.processedFilesCount record.processed_files_count
      json.analysisProgress record.analysis_progress
    end

    if options[:include_errors] && policy.admin?
      json.errors serialize(record.job_errors.to_a)
    end

    json.canceledAt record.canceled_at.iso8601(3) if record.canceled_at.present?
    json.scannedAt record.scanned_at.iso8601(3) if record.scanned_at.present?
    json.processedAt record.processed_at.iso8601(3) if record.processed_at.present?
    json.analysisFailedAt record.analysis_failed_at.iso8601(3) if record.analysis_failed_at.present?
    json.analyzedAt record.analyzed_at.iso8601(3) if record.analyzed_at.present?

    json.createdAt record.created_at.iso8601(3)
  end
end
