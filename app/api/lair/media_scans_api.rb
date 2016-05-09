module Lair
  class MediaScansApi < Grape::API
    namespace :scans do
      helpers do
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

          processing_scan = MediaScan.where('media_scans.source_id = ? AND media_scans.state IN (?)', record.source_id, %w(scanned)).first
          raise 'Scan already in progress' if processing_scan.present?

          record.save!

          MediaScan.where('media_scans.id != ? AND media_scans.source_id = ? AND media_scans.state NOT IN (?)', record.id, record.source_id, %w(canceled failed processed)).to_a.each do |incomplete_scan|
            incomplete_scan.cancel_scan!
          end

          serialize record
        end
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(MediaScan.where(api_id: params[:id].to_s))
          end
        end

        patch do
          authorize! MediaScan, :update

          MediaScan.transaction do

            record.files_count = params[:filesCount] if params.key? :filesCount

            if record.state == 'started' && params[:state] == 'scanned'
              record.close_scan!
            end

            record.save!
            serialize record
          end
        end

        namespace :files do
          post do
            authorize! MediaScan, :update

            raise 'Scan completed' if record.state.to_s != 'started'

            files = JSON.parse request.body.read
            raise 'Array required' unless files.kind_of? Array

            lock_for_update 'media_scans:scanned_files' do
              MediaScan.transaction do

                files = files.collect do |data|
                  MediaScanFile.new(scan_id: record.id).tap do |f|
                    f.path = data.delete 'path'
                    f.change_type = data.delete 'change'
                    f.data = data
                  end
                end

                file_changes = files.select{ |f| %w(added changed deleted).include?(f.change_type) && f.path }
                existing_paths = record.scanned_files.where(path: file_changes.collect(&:path)).to_a.collect &:path
                existing_paths_in_source = record.source.files.where(path: file_changes.collect(&:path), deleted: false).to_a.collect &:path

                validation_error = ValidationError.new 'Scanned files are invalid'

                file_changes.each.with_index do |file,i|
                  if existing_paths.include? file.path
                    validation_error.add message: "File #{file.path} was already scanned", path: "/#{i}/path"
                  end

                  if files.count{ |f| f.path == file.path } >= 2
                    validation_error.add message: "File #{file.path} is present multiple times in the request", path: "/#{i}/path"
                  end

                  if file.change_type == 'added' && existing_paths_in_source.include?(file.path)
                    validation_error.add message: "File #{file.path} cannot be added because it is already present in the media source", path: "/#{i}/change"
                  end

                  if %w(changed deleted).include?(file.change_type) && !existing_paths_in_source.include?(file.path)
                    validation_error.add message: "File #{file.path} cannot be #{file.change_type} because it does not exist in the media source", path: "/#{i}/change"
                  end
                end

                validation_error.raise_if_any

                MediaScanFile.import files, validate: true

                record.changed_files_count += files.length
                record.save!

                status 200
                files
              end
            end
          end
        end
      end
    end
  end
end
