module Lair
  class MediaScansApi < Grape::API
    namespace :scans do
      helpers do
        def update_record_from_params record
          record.source = MediaSource.where(api_id: params[:sourceId].to_s).first! if params.key? :sourceId
          record.scanner = MediaScanner.where(api_id: params[:scannerId].to_s).first! if params.key? :scannerId
          record.started_at = Time.now
        end
      end

      post do
        authorize! MediaScan, :create

        MediaScan.transaction do
          record = MediaScan.new
          update_record_from_params record
          record.save!

          now = Time.now
          MediaScan.where('media_scans.id != ? AND media_scans.source_id = ? AND media_scans.ended_at IS NULL', record.id, record.source_id).to_a.each do |incomplete_scan|
            incomplete_scan.update_attribute :ended_at, now
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
            record.ended_at = params[:endedAt].to_s if params.key? :endedAt
            record.save!
            serialize record
          end
        end

        namespace :files do
          post do
            authorize! MediaScan, :update

            raise 'Scan completed' if record.ended_at.present?

            files = JSON.parse request.body.read
            raise 'Array required' unless files.kind_of? Array

            MediaScan.transaction do

              files = files.collect do |data|
                MediaScanFile.new(scan_id: record.id, path: data.delete('path')).tap do |f|
                  f.data = data
                end
              end

              # TODO: batch validate
              MediaScanFile.import files, validate: true

              record.files_count += files.length
              record.save!

              ProcessMediaScanJob.enqueue record, files.length

              status 200
              files
            end
          end
        end
      end
    end
  end
end
