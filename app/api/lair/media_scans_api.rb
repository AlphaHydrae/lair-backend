module Lair
  class MediaScansApi < Grape::API
    namespace :scans do
      helpers do
        def serialization_options *args
          {
            include_source: include_in_response?(:source),
            source_options: {
              include_user: include_in_response?(:source)
            },
            include_errors: include_in_response?(:errors)
          }
        end

        def with_serialization_includes rel
          rel = rel.includes :source
        end

        def update_record_from_params record
          record.source = MediaSource.where(api_id: params[:sourceId].to_s).first! if params.key? :sourceId
          record.scanner = MediaScanner.where(api_id: params[:scannerId].to_s).first! if params.key? :scannerId
        end
      end

      post do
        authorize! MediaScan, :create

        MediaScan.transaction do

          record = MediaScan.new
          update_record_from_params record

          # TODO analysis: allow new scan if previous scan is analyzing
          processing_scan = MediaScan.where('media_scans.source_id = ? AND media_scans.state IN (?)', record.source_id, %w(scanned processing retrying_processing processed)).first
          raise 'Scan already in progress' if processing_scan.present?

          record.save!

          MediaScan.where('media_scans.id != ? AND media_scans.source_id = ? AND media_scans.state IN (?)', record.id, record.source_id, %w(scanning)).to_a.each do |incomplete_scan|
            incomplete_scan.cancel_scanning!
          end

          record.start_scanning!

          serialize record
        end
      end

      get do
        authorize! MediaScan, :index

        rel = policy_scope MediaScan.order('media_scans.created_at DESC')

        rel = paginated rel do |rel|
          rel
        end

        serialize load_resources(rel)
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(MediaScan.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! MediaScan, :show
          serialize record
        end

        patch do
          authorize! MediaScan, :update

          MediaScan.transaction do

            record.files_count = params[:filesCount] if params.key? :filesCount

            if record.state == 'scanning' && params[:state] == 'scanned'
              record.finish_scanning!
            end

            record.save!
            serialize record
          end
        end

        namespace :retry do
          post do
            authorize! record, :update

            MediaScan.transaction do
              if %w(processing_failed).include? record.state
                record.retry_processing!
              else
                error = ValidationError.new
                error.add "Scanning can only be retried from the processingFailed state"
                error.raise_if_any
              end

              serialize record
            end
          end
        end

        namespace :analysis do
          post do
            authorize! record, :analysis

            MediaScan.transaction do
              if %w(processed analyzed).include? record.state
                record.restart_analysis!
                event = ::Event.new(event_type: 'media:reanalysis:scan', user: current_user, trackable: record, trackable_api_id: record.api_id).tap &:save!
                AnalyzeMediaScanJob.enqueue record, event
              else
                error = ValidationError.new
                error.add "Scanning can only be reanalyzed from the processed or analyzed states"
                error.raise_if_any
              end
            end

            status 202
          end
        end

        namespace :changes do
          helpers do
            def serialization_options *args
              {
                include_data: include_in_response?(:data)
              }
            end

            def with_serialization_includes rel
              if rel.model == MediaScan
                rel = rel.includes :source
              elsif rel.model == MediaScanChange
                rel = rel.includes :scan
              else
                raise "Unsupported model #{rel.model}"
              end
            end
          end

          post do
            authorize! MediaScanChange, :create

            raise 'Scan completed' if record.state.to_s != 'scanning'

            changes = JSON.parse request.body.read
            raise 'Array required' unless changes.kind_of? Array

            lock_for_update "media_scan:#{record.api_id}:changes" do
              MediaScan.transaction do

                changes = changes.collect do |data|
                  MediaScanChange.new(scan_id: record.id).tap do |f|
                    f.path = data.delete 'path'
                    f.change_type = data.delete 'change'
                    f.data = data
                  end
                end

                valid_changes = changes.select{ |f| %w(added modified deleted).include?(f.change_type) && f.path }
                existing_paths = record.file_changes.where(path: valid_changes.collect(&:path)).to_a.collect &:path
                existing_paths_in_source = record.source.files.where(path: valid_changes.collect(&:path), deleted: false).to_a.collect &:path

                validation_error = ValidationError.new 'Scanned changes are invalid'

                valid_changes.each.with_index do |change,i|
                  if existing_paths.include? change.path
                    validation_error.add message: "File #{change.path} was already scanned", path: "/#{i}/path"
                  end

                  if changes.count{ |f| f.path == change.path } >= 2
                    validation_error.add message: "File #{change.path} is present multiple times in the request", path: "/#{i}/path"
                  end

                  if change.change_type == 'added' && existing_paths_in_source.include?(change.path)
                    validation_error.add message: "File #{change.path} cannot be added because it is already present in the media source", path: "/#{i}/change"
                  end

                  if %w(modified deleted).include?(change.change_type) && !existing_paths_in_source.include?(change.path)
                    validation_error.add message: "File #{change.path} cannot be #{change.change_type} because it does not exist in the media source", path: "/#{i}/change"
                  end
                end

                validation_error.raise_if_any

                MediaScanChange.import changes, validate: true

                changes.each do |change|
                  column = "#{change.change_type}_files_count"
                  record.send "#{column}=", record.send(column) + 1
                end

                record.save!

                status 201
                changes
              end
            end
          end

          get do
            authorize! MediaScanChange, :index

            rel = policy_scope MediaScanChange.where(scan: record).order('media_scan_changes.path ASC').includes(:scan)

            rel = paginated rel do |rel|
              rel
            end

            serialize load_resources(rel)
          end
        end
      end
    end
  end
end
