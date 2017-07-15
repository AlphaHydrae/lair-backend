class MediaScanSerializer < ApplicationSerializer
  def build json, options = {}
    json.id record.api_id
    json.state record.state.to_s.camelize(:lower)

    json.sourceId record.source.api_id
    json.source serialize(record.source, options[:source_options] || {}) if options[:include_source]

    json.changedFilesCount record.changed_files_count
    json.filesCount record.files_count if record.scanning_finished?
    json.processedFilesCount record.processed_files_count if record.processing_started?
    json.analysisProgress record.analysis_progress if record.analysis_started?

    if options[:include_errors] && policy.admin?
      json.errors serialize(record.job_errors.to_a)
    end

    %i(canceled_at scanning_at scanned_at processing_at processing_failed_at retrying_processing_at processed_at analyzed_at created_at).each do |ts|
      json.set! ts.to_s.camelize(:lower), record.send(ts).iso8601(3) if record.send(ts).present?
    end
  end
end
