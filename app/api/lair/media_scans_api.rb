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
              record.finish_scan!
            end

            record.save!
            serialize record
          end
        end

        namespace :files do
          post do
            authorize! MediaScan, :update

            raise 'Scan completed' if record.scanned_at.present?

            files = JSON.parse request.body.read
            raise 'Array required' unless files.kind_of? Array

            MediaScan.transaction do

              files = files.collect do |data|
                MediaScanFile.new(scan_id: record.id).tap do |f|
                  f.path = data.delete 'path'
                  f.change_type = data.delete 'change'
                  f.data = data
                end
              end

              # TODO: batch validate
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
